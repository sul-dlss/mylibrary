# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
