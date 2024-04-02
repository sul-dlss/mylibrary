# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user?, :patron, :patron_or_group
  before_action :set_internal_pages_flash_message, :check_unavailable

  class_attribute :ils_client_class, default: Settings.ils.client.constantize
  class_attribute :ils_patron_model_class, default: Settings.ils.patron_model.constantize

  def current_user
    request.env['warden'].user
  end

  def current_user?
    current_user.present?
  end

  def patron
    return unless current_user?

    @patron ||= ils_patron_model_class.new(patron_info_response)
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
    # do not attempt redeirect to '/unavailable' if:
    # - you are already there (infinite loop)
    # - you do not have an active session (root_path; otherwise you would never be able to log in again..)
    return if request.path == unavailable_path || request.path == root_path

    redirect_to unavailable_path unless ils_client.ping
  end

  def patron_info_response
    ils_client.patron_info(current_user.patron_key)
  end

  def ils_client
    @ils_client ||= ils_client_class.new
  end

  def authenticate_user!
    redirect_to root_url unless current_user?
  end

  def logout_user!
    redirect_to logout_path if current_user?
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
