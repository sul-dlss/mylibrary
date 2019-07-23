# frozen_string_literal: true

# :nodoc:
class SummariesController < ApplicationController
  before_action :authenticate_user!

  # GET /summaries
  # GET /summaries.json
  def index
    @patron = patron
  end
end
