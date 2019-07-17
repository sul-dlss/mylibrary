# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @fine_response = symphony_client.fines(current_user.patron_key)
    @checkouts_response = symphony_client.checkouts(current_user.patron_key)
    @fines = @fine_response['fields']['blockList'].map { |fine| Fine.new(fine) }
    @checkouts = @checkouts_response['fields']['circRecordList'].map { |checkout| Checkout.new(checkout) }
  end
end
