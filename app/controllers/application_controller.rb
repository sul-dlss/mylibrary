# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user?, :patron, :patron_or_group, :symphony_client
  before_action :set_internal_pages_flash_message, :check_unavailable

  def current_user
    session_data = request.env['warden'].user
    session_data && User.new(session_data)
  end

  def current_user?
    current_user.present?
  end

  def patron
    return unless current_user?

    @patron ||= Patron.new(patron_info_response, payment_in_process_cookie)
  end

  def patron_or_group
    return unless patron

    if params[:group]
      patron.group
    else
      patron
    end
  end

  private

  def check_unavailable
    return if request.path == unavailable_path || request.path == root_path

    redirect_to unavailable_path unless symphony_client.ping
  end

  ##
  # Used in conjuction with Patron to determine if fines should be filtered by
  # in flight payment sequence
  def payment_in_process_cookie
    @payment_in_process_cookie ||= JSON.parse(cookies[:payment_in_process] || {}.to_json).with_indifferent_access
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  def patron_info_response
    symphony_client.patron_info(current_user.patron_key, item_details: item_details)
  end

  def authenticate_user!
    redirect_to root_url unless current_user?
  end

  def logout_user!
    redirect_to logout_path if current_user?
  end

  def item_details
    {}
  end

  def set_internal_pages_flash_message
    return unless Settings.internal_pages_flash_message_html.present? && action_name == 'index'

    Settings.internal_pages_flash_message_config.each do |controller|
      # rubocop:disable Rails/OutputSafety
      controller == controller_name && flash.now[:alert] = Settings.internal_pages_flash_message_html.html_safe
      # rubocop:enable Rails/OutputSafety
    end
  end
end
