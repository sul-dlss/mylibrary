# frozen_string_literal: true

# Controller for the requests page
class RequestsController < ApplicationController
  before_action :authenticate_user!

  # A sufficiently large time used to sort nil values last
  # TODO: Update before 2099
  END_OF_DAYS = Time.zone.parse('2099-01-01')

  def index
    @requests = patron_or_group.requests.sort_by do |request|
      [request.expiration_date || END_OF_DAYS, request.fill_by_date || END_OF_DAYS]
    end
  end

  def destroy
    @response = symphony_client.cancel_hold(*cancel_hold_params)
    case @response.status
    when 200
      flash[:success] = t 'mylibrary.request.cancel.success_html', title: params['title']
    else
      flash[:error] = t 'mylibrary.request.cancel.error_html', title: params['title']
    end
    redirect_to requests_path
  end

  private

  def cancel_hold_params
    params.require(%I[resource id])
  end
end
