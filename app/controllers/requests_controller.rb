# frozen_string_literal: true

# Controller for the requests page
class RequestsController < ApplicationController
  before_action :authenticate_user!

  # A sufficiently large time used to sort nil values last
  # TODO: Update before 2099
  END_OF_DAYS = Time.zone.parse('2099-01-01')

  def index
    @response = symphony_client.requests(current_user.patron_key)
    @requests = @response['fields']['holdRecordList'].map { |request| Request.new(request) }.sort_by do |request|
      [request.pickup_date || END_OF_DAYS, request.fill_by_date || END_OF_DAYS, request.expiration_date || END_OF_DAYS]
    end
  end
end
