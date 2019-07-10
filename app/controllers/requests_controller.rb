# frozen_string_literal: true

# Controller for the requests page
class RequestsController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
