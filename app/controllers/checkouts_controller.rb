# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def index
    @checkouts = patron_or_group.checkouts.sort_by { |x| x.sort_key(:due_date) }
  end
end
