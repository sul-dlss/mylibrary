# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @fines = patron.fines
    @checkouts = patron.checkouts
  end
end
