# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def index
    @checkouts = if params[:group]
                   patron.group.checkouts.sort_by(&:due_date)
                 else
                   patron.checkouts.sort_by(&:due_date)
                 end
  end
end
