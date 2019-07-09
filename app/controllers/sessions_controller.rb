# frozen_string_literal: true

# :nodoc:
class SessionsController < ApplicationController
  def index
    redirect_to summaries_url if current_user?
  end

  def form; end

  def login_by_library_id
    if request.env['warden'].authenticate(:library_id)
      redirect_to summaries_url
    else
      redirect_to login_url, alert: 'Unable to authenticate.'
    end
  end

  def login_by_sunetid
    if request.env['warden'].authenticate(:shibboleth, :development_shibboleth_stub)
      redirect_to summaries_url
    else
      redirect_to root_url, alert: 'Unable to authenticate.'
    end
  end

  def destroy
    request.env['warden'].logout
    redirect_to root_url
  end
end
