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
    @response = ils_client.renew_item(*renew_item_params)

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
    response = ils_client.renew_items(eligible_renewals)

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
      items: tag.ul(
        safe_join(response[type].collect { |renewal| tag.li(renewal.title) }, '')
      )
    )
  end

  def renew_item_params
    params.require(%I[resource item_key])
  end

  # Make sure the checkout belongs to the user trying to do the renewal, and
  # also make sure the item is not renewable for reasons that symphony doesn't
  # know about (e.g. the itemCat5 hack we're doing during COVID-19 times; other
  # conditions are handled by business logic in Symphony so we don't need to
  # worry about being exhaustive here.)
  def authorize_update!
    checkout = patron_or_group.checkouts.find { |request| request.item_key == params.require(:item_key) }

    raise CheckoutException, 'Error' if checkout.nil? || checkout.item_category_non_renewable?
  end

  def deny_access
    flash[:error] = t 'mylibrary.renew_item.deny_access'

    redirect_to checkouts_path(group: params[:group])
  end
end
