# frozen_string_literal: true

# Controller for reseting a Barcode+PIN user's PIN
class ResetPinsController < ApplicationController
  before_action :logout_user!

  # Renders the first step for reseting the PIN
  #
  # GET /reset_pin
  def index; end

  # Trigger a reset request for the PIN in Symphony; this will
  # send the patron an email (using their email adddress on file)
  # with a link back to our change form and a token for completing the reset
  #
  # POST /reset_pin
  def reset
    @response = symphony_client.reset_pin(
      params['library_id'],
      change_pin_with_token_unencoded_url
    )
    flash[:success] = t 'mylibrary.reset_pin.success_html', library_id: params['library_id']
    render action: :index
  end

  # Renders the third step for reseting a PIN, where we prompt the user
  # to enter a new pin
  #
  # GET /change_pin/:token
  def change_form; end

  # Finally, trigger the PIN update in Symphony using the token the user
  # received in their email and the new PIN the just entered
  #
  # POST /change_pin
  def change
    @response = symphony_client.change_pin(*change_pin_with_token_params)

    case @response.status
    when 200
      flash[:success] = t 'mylibrary.change_pin.success_html'
      redirect_to login_path
    else
      flash[:error] = t 'mylibrary.change_pin.error_html'
      redirect_to reset_pin_path
    end
  end

  private

  def change_pin_with_token_params
    params.require(%I[token pin])
  end

  ##
  # Hacky workaround Rails routing helpers to have the <> not encoded
  # Symphony looks for the string <RESET_PIN_TOKEN> and injects the actual token
  # in a URL crafted in the email sent to the user.
  def change_pin_with_token_unencoded_url
    change_pin_with_token_url('foo').gsub('foo', '<RESET_PIN_TOKEN>')
  end
end
