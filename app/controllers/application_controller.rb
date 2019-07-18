# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user?, :patron

  def current_user
    session_data = request.env['warden'].user
    session_data && User.new(session_data)
  end

  def current_user?
    current_user.present?
  end

  def patron
    return unless current_user?

    @patron ||= Patron.new(symphony_client.patron_info(current_user.patron_key))
  end

  private

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  def authenticate_user!
    redirect_to root_url unless current_user?
  end

  def logout_user!
    redirect_to logout_path if current_user?
  end
end
