# frozen_string_literal: true

# Controller for scheduling library visits
class SchedulesController < ApplicationController
  before_action :authenticate_user!

  def show
    @oncehub_id = Settings.oncehub.dig(params[:type], params[:id])

    raise ActionController::RoutingError, 'Not Found' unless @oncehub_id

    render layout: !request.xhr?
  end

  def libcal_pickup
    @libcal_settings = Settings.libcal[params[:id]]
    raise ActionController::RoutingError, 'Not Found' unless @libcal_settings

    render layout: !request.xhr?
  end
end
