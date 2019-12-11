# frozen_string_literal: true

# :nodoc:
class SummariesController < ApplicationController
  before_action :authenticate_user!

  # Render the summary dashboard for a patron or group
  #
  # GET /summaries
  # GET /summaries.json
  def index
    @patron = patron

    redirect_to unavailable_path if patron.record_unavailable?
  end

  def unavailable; end
end
