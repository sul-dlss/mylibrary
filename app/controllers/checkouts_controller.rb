# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  def index; end

  # Do a request to Symphony here
  def show; end

  def checkouts_params
    params.permit(id: {})
  end
end
