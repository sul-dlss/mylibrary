# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user?

  def current_user
    session_data = request.env['warden'].user
    session_data && User.new(session_data)
  end

  def current_user?
    current_user.present?
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  private

  def authenticate_user!
    redirect_to root_url unless current_user?
  end
end
