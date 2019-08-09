# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  # Render a list of checkouts for the patron or research group
  #
  # GET /checkouts
  # GET /checkouts.json
  def index
    @checkouts = patron_or_group.checkouts.sort_by { |x| x.sort_key(:due_date) }
  end

  # GET /checkouts/new
  def new; end

  # POST /checkouts
  def create
    response = symphony_client.checkout(patron_or_group.barcode, params[:barcode])

    case response.status
    when 200
      flash[:success] = t 'mylibrary.checkout.success_html' #, title: params['title']
    else
      Rails.logger.error(response.body)
      flash[:error] = t 'mylibrary.checkout.error_html' # , title: params['title']
    end

    redirect_to checkouts_path(group: params[:group])
  end

  private

  def item_details
    { circRecordList: true }
  end
end
