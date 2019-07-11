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
    needs_shibboleth_logout = current_user&.shibboleth?
    request.env['warden'].logout

    if needs_shibboleth_logout
      redirect_to '/Shibboleth.sso/Logout'
    else
      redirect_to root_url
    end
  end
end
