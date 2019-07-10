# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user

  def current_user
    request.env['warden'].user
  end

  def current_user?
    current_user.present?
  end

  private

  def authenticate_user!
    redirect_to root_url unless current_user?
  end
end
