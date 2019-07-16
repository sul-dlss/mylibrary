# frozen_string_literal: true

# :nodoc:
class ResetPinsController < ApplicationController
  before_action :logout_user!

  def index; end

  def reset
    @response = symphony_client.reset_pin(params['library_id'])
    flash[:success] = t 'mylibrary.reset_pin.success_html', library_id: params['library_id']
    redirect_to login_path
  end
end
