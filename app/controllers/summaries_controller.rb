# frozen_string_literal: true

# :nodoc:
class SummariesController < ApplicationController
  before_action :authenticate_user!

  # GET /summaries
  # GET /summaries.json
  def index; end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def summary_params
    params.fetch(:summary, {})
  end
end
