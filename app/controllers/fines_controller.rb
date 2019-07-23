# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @fines = if params[:group]
               patron.group_fines
             else
               patron.fines
             end
    @checkouts = if params[:group]
                   patron.group_checkouts.sort_by(&:due_date)
                 else
                   patron.checkouts.sort_by(&:due_date)
                 end
  end
end
