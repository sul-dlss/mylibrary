# frozen_string_literal: true

# Controller for the requests page
class RequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    @requests = patron_or_group.requests.sort_by { |request| request.sort_key(:date) }
  end
end
