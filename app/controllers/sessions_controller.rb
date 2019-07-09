# frozen_string_literal: true

# :nodoc:
class SessionsController < ApplicationController
  def index
    redirect_to summaries_url if current_user?
  end
end
