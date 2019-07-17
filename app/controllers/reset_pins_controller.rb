# frozen_string_literal: true

# :nodoc:
class ResetPinsController < ApplicationController
  before_action :logout_user!

  def index; end

  def change_form; end

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

  def reset
    @response = symphony_client.reset_pin(
      params['library_id'],
      change_pin_with_token_unencoded_url
    )
    flash[:success] = t 'mylibrary.reset_pin.success_html', library_id: params['library_id']
    render action: :index
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
