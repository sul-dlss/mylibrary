# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def index
    @response = symphony_client.checkouts(current_user['patronKey'])
    @checkouts = @response['fields']['circRecordList'].map { |checkout| Checkout.new(checkout) }
  end
end
