# frozen_string_literal: true

# Controller for the requests page
class RequestsController < ApplicationController
  before_action :authenticate_user!

  # A sufficiently large time used to sort nil values last
  # TODO: Update before 2099
  END_OF_DAYS = Time.zone.parse('2099-01-01')

  def index
    @requests = if params[:group]
                  patron.group.requests.sort_by do |request|
                    [request.expiration_date || END_OF_DAYS, request.fill_by_date || END_OF_DAYS]
                  end
                else
                  patron.requests.sort_by do |request|
                    [request.expiration_date || END_OF_DAYS, request.fill_by_date || END_OF_DAYS]
                  end
                end
  end
end
