# frozen_string_literal: true

# Controller for user requests/holds/etc
class RequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_update!, except: :index
  rescue_from RequestException, with: :deny_access

  # Renders user requests from Symphony and/or BorrowDirect
  #
  # GET /requests
  # GET /requests.json
  def index
    @requests = patron_or_group.requests
                               .sort_by { |request| request.sort_key(:date) }
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

  # Handles form submission for changing or canceling requests/holds/etc in Symphony
  #
  # PATCH /requests/:id
  # PUT /requests/:id
  def update
    destroy && return if params['cancel'].present?

    flash[:success] = []
    flash[:error] = []

    handle_pickup_change_request if params['service_point'].present?
    handle_not_needed_after_request if params['not_needed_after'].present? &&
                                       params['not_needed_after'] != params['current_fill_by_date']

    redirect_to requests_path(group: params[:group])
  end

  # Handles form submission for canceling requests/holds/etc in Symphony
  #
  # DELETE /requests/:id
  def destroy
    @response = ils_client.cancel_hold(*cancel_hold_params, patron_or_group.key)

    case @response.status
    # The FOLIO API returns 204
    # TODO: after FOLIO launch remove the 200 case which was the Symphony response
    when 200, 204
      flash[:success] = t 'mylibrary.request.cancel.success_html', title: params['title']
    else
      Rails.logger.error(@response.body)
      flash[:error] = t 'mylibrary.request.cancel.error_html', title: params['title']
    end

    redirect_to requests_path(group: params[:group])
  end

  private

  def handle_pickup_change_request
    change_pickup_response = ils_client.change_pickup_library(*change_pickup_params)
    case change_pickup_response.status
    # The FOLIO API returns 204
    # TODO: after FOLIO launch remove the 200 case which was the Symphony response
    when 200, 204
      flash[:success].push(t('mylibrary.request.update_pickup.success_html', title: params['title']))
    else
      Rails.logger.error(change_pickup_response.body)
      flash[:error].push(t('mylibrary.request.update_pickup.error_html', title: params['title']))
    end
  end

  def handle_not_needed_after_request
    not_needed_after_response = ils_client.not_needed_after(*not_needed_after_params)
    case not_needed_after_response.status
    # The FOLIO API returns 204
    # TODO: after FOLIO launch remove the 200 case which was the Symphony response
    when 200, 204
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
    # TODO: after Folio launch remove conditional wrapper and delete the else (Symphony) part
    if ils_client.is_a?(FolioClient)
      params.require(%I[id service_point])
    else
      params.require(%I[resource id service_point])
    end
  end

  def not_needed_after_params
    params.require(%I[resource id not_needed_after])
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
