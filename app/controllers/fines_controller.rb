# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @fines = fines
    @checkouts = checkouts
    @payments = if payments
                  Array.wrap(payments).map { |payment| Payment.new(payment) }
                else
                  []
                end
  end

  private

  def fines
    if params[:group]
      patron.group_fines
    else
      patron.fines
    end
  end

  def checkouts
    if params[:group]
      patron.group_checkouts.sort_by(&:due_date)
    else
      patron.checkouts.sort_by(&:due_date)
    end
  end

  def payments_response
    symphony_legacy_client.payments(symphony_client.session_token, patron)
  end

  def payments
    (Hash.from_xml(Nokogiri::XML(payments_response).to_s) || {}).dig('LookupPatronInfoResponse', 'feeInfo')
  end
end
