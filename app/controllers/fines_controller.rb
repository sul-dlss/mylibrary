# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @response = symphony_client.fines(current_user.patron_key)
    @fines = @response['fields']['blockList'].map { |fine| Fine.new(fine) }
  end
end
