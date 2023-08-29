# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user?, :patron, :patron_or_group
  before_action :set_internal_pages_flash_message, :check_unavailable, :check_sym_patron_key

  class_attribute :ils_client_class, default: Settings.ils.client.constantize
  class_attribute :ils_patron_model_class, default: Settings.ils.patron_model.constantize

  def current_user
    session_data = request.env['warden'].user
    session_data && User.new(session_data)
  end

  def current_user?
    current_user.present?
  end

  def patron
    return unless current_user?

    @patron ||= ils_patron_model_class.new(patron_info_response, payment_in_process_cookie)
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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def check_sym_patron_key
    return if request.path == root_path || current_user&.patron_key.blank? || symphony?

    # Symphony used numeric patron keys; FOLIO uses UUIDs
    return if current_user&.patron_key&.match?(/\A[+-]?\d+\Z/)

    request.env['warden'].logout
    redirect_to root_url
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  def symphony?
    Settings.ils.client == 'SymphonyClient'
  end

  ##
  # Used in conjuction with Patron to determine if fines should be filtered by
  # in flight payment sequence
  # TODO: remove payment cookie methods when migration off of Symphony is complete
  def payment_in_process_cookie
    @payment_in_process_cookie ||= JSON.parse(cookies[:payment_in_process] || {}.to_json).with_indifferent_access
  end

  def patron_info_response
    ils_client.patron_info(current_user.patron_key, item_details: item_details)
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
