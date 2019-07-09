# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user_name

  def current_user
    request.env['warden'].user
  end

  def current_user?
    current_user.present?
  end

  def current_user_name
    current_user? && current_user['name'].present? ? current_user['name'].split(',').reverse.join(' ') : nil
  end

  private

  def authenticate_user!
    redirect_to root_url unless current_user?
  end
end
