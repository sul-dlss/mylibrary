# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  # Render a list of checkouts for the patron or research group
  #
  # GET /checkouts
  # GET /checkouts.json
  def index
    @checkouts = patron_or_group.checkouts.sort_by { |x| x.sort_key(:due_date) }
    @requests = patron_or_group.requests.sort_by { |request| request.sort_key(:date) }
  end
end
