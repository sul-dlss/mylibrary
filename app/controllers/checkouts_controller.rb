# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def index
    @response = symphony_client.checkouts(current_user.patron_key)
    @checkouts = @response['fields']['circRecordList'].map { |checkout| Checkout.new(checkout) }
  end
end
