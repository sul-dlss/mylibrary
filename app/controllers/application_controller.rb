# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user?, :patron, :patron_or_group, :symphony_client, :payment_processing?

  def current_user
    session_data = request.env['warden'].user
    session_data && User.new(session_data)
  end

  def payment_processing?
    payment_in_process_cookie[:pending] && patron_or_group.all_fines.any?
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
end
