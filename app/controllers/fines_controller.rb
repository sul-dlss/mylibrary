# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @fines = fines
    @checkouts = checkouts
    @payments = if payments
                  Array.wrap(payments).map { |payment| Payment.new(payment) }.sort_by(&:sort_key).reverse
                else
                  []
                end
  end

  private

  def fines
    patron_or_group.fines
  end

  def checkouts
    patron_or_group.checkouts.sort_by(&:due_date)
  end

  def payments_response
    symphony_legacy_client.payments(symphony_client.session_token, patron)
  end

  def payments
    (Hash.from_xml(Nokogiri::XML(payments_response).to_s) || {}).dig('LookupPatronInfoResponse', 'feeInfo')
  end

  def item_details
    { blockList: true }
  end
end
