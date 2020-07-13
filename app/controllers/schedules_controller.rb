# frozen_string_literal: true

# Controller for scheduling library visits
class SchedulesController < ApplicationController
  before_action :authenticate_user!

  def show
    render layout: !request.xhr?
  end

  def business_pickup
    render layout: !request.xhr?
  end
end
