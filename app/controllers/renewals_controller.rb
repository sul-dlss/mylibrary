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
    @response = ils_client.renew_item_by_id(patron_or_group.key, *renew_item_params)

    case @response.status
    when 200, 201
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

    bulk_renewal_success_flash(response)
    bulk_renewal_error_flash(response)

    redirect_to checkouts_path(group: params[:group])
  end

  private

  def bulk_renewal_success_flash(response)
    return unless response[:success].any?

    flash[:success] = I18n.t('mylibrary.renew_all_items.success_html', count: response[:success].length)
  end

  def bulk_renewal_error_flash(response)
    return unless response[:error].any?

    flash[:error] = I18n.t('mylibrary.renew_all_items.error_html',
                           count: response[:error].length,
                           items: tag.ul(safe_join(response[:error].collect do |renewal|
                                                     tag.li(renewal.title.truncate_words(7))
                                                   end, '')))
  end

  def renew_item_params
    params.require(%I[item_id])
  end

  # Make sure the checkout belongs to the user trying to do the renewal
  # and make sure the item is renewable
  def authorize_update!
    checkout = patron_or_group.checkouts.find { |request| request.item_id == params.require(:item_id) }

    raise CheckoutException, 'Error' if checkout.nil? || checkout.item_category_non_renewable?
  end

  def deny_access
    flash[:error] = t 'mylibrary.renew_item.deny_access'

    redirect_to checkouts_path(group: params[:group])
  end
end
