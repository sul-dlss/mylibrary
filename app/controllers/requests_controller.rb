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

  def edit
    @request = patron.requests.find { |r| r.key == params['id'] }
    respond_to do |format|
      format.html do
        return render layout: false if request.xhr?
      end
    end
  end

  def update
    destroy && return if params['cancel'].present?
    flash[:success] = []
    flash[:error] = []
    handle_pickup_change_request if params['pickup_library'].present?
    handle_not_needed_after_request if params['not_needed_after'].present? &&
                                       params['not_needed_after'] != params['current_fill_by_date']
    redirect_to requests_path
  end

  def destroy
    @response = symphony_client.cancel_hold(*cancel_hold_params)
    case @response.status
    when 200
      flash[:success] = t 'mylibrary.request.cancel.success_html', title: params['title']
    else
      Rails.logger.error(@response.body)
      flash[:error] = t 'mylibrary.request.cancel.error_html', title: params['title']
    end
    redirect_to requests_path
  end

  private

  def handle_pickup_change_request
    change_pickup_response = symphony_client.change_pickup_library(*change_pickup_params)
    case change_pickup_response.status
    when 200
      flash[:success].push(t('mylibrary.request.update_pickup.success_html', title: params['title']))
    else
      Rails.logger.error(change_pickup_response.body)
      flash[:error].push(t('mylibrary.request.update_pickup.error_html', title: params['title']))
    end
  end

  def handle_not_needed_after_request
    not_needed_after_response = symphony_client.not_needed_after(*not_needed_after_params)
    case not_needed_after_response.status
    when 200
      flash[:success].push(t('mylibrary.request.update_not_needed_after.success_html', title: params['title']))
    else
      Rails.logger.error(not_needed_after_response.body)
      flash[:error].push(t('mylibrary.request.update_not_needed_after.error_html', title: params['title']))
    end
  end

  def cancel_hold_params
    params.require(%I[resource id])
  end

  def change_pickup_params
    params.require(%I[resource id pickup_library])
  end

  def not_needed_after_params
    params.require(%I[resource id not_needed_after])
  end
end
