# frozen_string_literal: true

# Controller for renewing items
class RenewalsController < ApplicationController
  include ActionView::Context
  include ActionView::Helpers::TagHelper
  before_action :authenticate_user!
  before_action :authorize_update!, only: :create
  rescue_from CheckoutException, with: :deny_access

  # Renew a single item for a patron
  #
  # POST /renewals
  def create
    @response = symphony_client.renew_item(*renew_item_params)

    case @response.status
    when 200
      flash[:success] = t 'mylibrary.renew_item.success_html', title: params['title']
    else
      flash[:error] = t 'mylibrary.renew_item.error_html', title: params['title']
    end

    redirect_to checkouts_path(group: params[:group])
  end

  # Renew all eligible items for a patron
  #
  # POST /renewals/all_eligible
  def all_eligible
    eligible_renewals = patron_or_group.checkouts.select(&:renewable?)
    response = symphony_client.renew_items(eligible_renewals)

    bulk_renewal_flash(response, type: :success)
    bulk_renewal_flash(response, type: :error)

    redirect_to checkouts_path(group: params[:group])
  end

  private

  def item_details
    { circRecordList: true }
  end

  def bulk_renewal_flash(response, type:)
    return unless response[type].any?

    flash[type] = I18n.t(
      "mylibrary.renew_all_items.#{type}_html",
      count: response[type].length,
      items: content_tag(
        'ul',
        safe_join(response[type].collect { |renewal| content_tag('li', renewal.title) }, '')
      )
    )
  end

  def renew_item_params
    params.require(%I[resource item_key])
  end

  def authorize_update!
    return if patron_or_group.checkouts.any? { |request| request.item_key == params.require(:item_key) }

    raise CheckoutException, 'Error'
  end

  def deny_access
    flash[:error] = 'An unexpected error has occurred'

    redirect_to checkouts_path(group: params[:group])
  end
end
