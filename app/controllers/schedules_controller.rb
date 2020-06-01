# frozen_string_literal: true

# Controller for scheduling library visits
class SchedulesController < ApplicationController
  before_action :authenticate_user!

  def show
    @patron = patron
    render layout: !request.xhr?
  end
end
