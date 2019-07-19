# frozen_string_literal: true

# Controller for renewing items
class RenewalsController < ApplicationController
  before_action :authenticate_user!

  def create
    @response = symphony_client.renew_item(*renew_item_params)
    case @response.status
    when 200
      flash[:success] = t 'mylibrary.renew_item.success_html', title: params['title']
    else
      flash[:error] = t 'mylibrary.renew_item.error_html', title: params['title']
    end
    redirect_to checkouts_path
  end

  private

  def renew_item_params
    params.require(%I[resource item_key])
  end
end
