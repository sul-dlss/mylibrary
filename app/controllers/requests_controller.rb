# frozen_string_literal: true

# Controller for user requests/holds/etc
class RequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_update!, except: :index
  rescue_from RequestException, with: :deny_access

  # Renders user requests from FOLIO and/or BorrowDirect
  #
  # GET /requests
  # GET /requests.json
  def index
    @requests = patron_or_group.requests
                               .sort_by { |request| request.sort_key(:date) }
    # Illiad requests don't interact with groups
    @illiad_requests = patron.illiad_requests
                             .sort_by { |request| request.sort_key(:date) }
    @combined_requests = @requests.concat(@illiad_requests).sort_by { |request| request.sort_key(:date) }
  end

  # Renders a form for editing a request/hold
  #
  # GET /requests/:id/edit
  def edit
    @request = patron_or_group.requests.find { |r| r.key == params['id'] }

    respond_to do |format|
      format.html do
        return render layout: false if request.xhr?
      end
    end
  end

  # Handles form submission for changing or canceling requests/holds/etc in FOLIO
  #
  # PATCH /requests/:id
  # PUT /requests/:id
  def update
    destroy && return if params['cancel'].present?

    flash[:success] = []
    flash[:error] = []

    handle_change_pickup_service_point if params['service_point'].present?
    handle_change_pickup_expiration if params['not_needed_after'].present? &&
                                       params['not_needed_after'] != params['current_fill_by_date']

    redirect_to requests_path(group: params[:group])
  end

  # Handles form submission for canceling requests/holds/etc in FOLIO
  #
  # DELETE /requests/:id
  def destroy
    @response = ils_client.cancel_request(*cancel_request_params, patron_or_group.key)

    case @response.status
    when 204
      flash[:success] = t 'mylibrary.request.cancel.success_html', title: params['title']
    else
      Rails.logger.error(@response.body)
      flash[:error] = t 'mylibrary.request.cancel.error_html', title: params['title']
    end

    redirect_to requests_path(group: params[:group])
  end

  private

  def handle_change_pickup_service_point
    response_flash_message(response: ils_client.change_pickup_service_point(*change_pickup_service_point_params),
                           translation_key: 'change_pickup_service_point')
  end

  def handle_change_pickup_expiration
    response_flash_message(response: ils_client.change_pickup_expiration(*change_pickup_expiration_params),
                           translation_key: 'change_pickup_expiration')
  end

  def response_flash_message(response:, translation_key:)
    case response.status
    when 204
      flash[:success].push(t("mylibrary.request.#{translation_key}.success_html", title: params['title']))
    else
      Rails.logger.error(response.body)
      flash[:error].push(t("mylibrary.request.#{translation_key}.success_html", title: params['title']))
    end
  end

  def cancel_request_params
    params.require(%I[id])
  end

  def change_pickup_service_point_params
    params.require(%I[id service_point])
  end

  def change_pickup_expiration_params
    params.require(%I[id not_needed_after])
  end

  def item_details
    { holdRecordList: true }
  end

  def authorize_update!
    return if patron_or_group.requests.any? { |request| request.key == params[:id] }

    raise RequestException, 'Error'
  end

  def deny_access
    flash[:error] = t 'mylibrary.request.deny_access'

    redirect_to requests_path(group: params[:group])
  end
end
