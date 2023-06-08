# frozen_string_literal: true

# Controller for reseting a Barcode+PIN user's PIN
class ResetPinsController < ApplicationController
  before_action :logout_user!
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found
  rescue_from ActiveSupport::MessageEncryptor::InvalidMessage, with: :invalid_token
  rescue_from FolioClient::IlsError, SymphonyClient::IlsError, with: :request_failed

  # Renders the first step for resetting the PIN
  #
  # GET /reset_pin
  def index; end

  # Trigger a reset request for the PIN; this will
  # send the patron an email (using their email address on file)
  # with a link back to our change form and a token for completing the reset
  #
  # POST /reset_pin
  def reset
    ils_client.reset_pin(reset_pin_params, change_pin_with_token_unencoded_url)
    flash[:success] = t 'mylibrary.reset_pin.success_html', library_id: params['library_id']
    redirect_to login_path
  end

  # Renders the third step for resetting a PIN, where we prompt the user
  # to enter a new pin
  #
  # GET /change_pin/:token
  def change_form; end

  # Finally, trigger the PIN update in the ILS using the token the user
  # received in their email and the new PIN they just entered
  #
  # POST /change_pin
  def change
    ils_client.change_pin(*change_pin_with_token_params)
    flash[:success] = t 'mylibrary.change_pin.success_html'
    redirect_to login_path
  end

  private

  def reset_pin_params
    params.require(:library_id)
  end

  def change_pin_with_token_params
    params.require(%I[token pin])
  end

  def user_not_found
    flash[:error] = t 'mylibrary.reset_pin.user_not_found_html'
    redirect_to reset_pin_path
  end

  def invalid_token
    flash[:error] = t 'mylibrary.change_pin.invalid_token_html'
    redirect_to reset_pin_path
  end

  def request_failed
    flash[:error] = t 'mylibrary.reset_pin.request_failed_html'
    redirect_to reset_pin_path
  end

  ##
  # Hacky workaround Rails routing helpers to have the <> not encoded
  # Symphony looks for the string <RESET_PIN_TOKEN> and injects the actual token
  # in a URL crafted in the email sent to the user.
  # TODO: remove this once we move to FOLIO
  def change_pin_with_token_unencoded_url
    change_pin_with_token_url('foo').gsub('foo', '<RESET_PIN_TOKEN>')
  end
end
