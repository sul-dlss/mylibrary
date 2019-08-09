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
  def new
    respond_to do |format|
      format.html do
        return render layout: false if request.xhr?
      end
    end
  end

  # POST /checkouts
  def create
    response = symphony_client.checkout(patron_or_group.barcode, *checkout_params)

    case response.status
    when 200
      flash[:success] = t 'mylibrary.checkout.success_html' #, title: params['title']
    else
      Rails.logger.error(response.body)
      flash[:error] = t 'mylibrary.checkout.error_html' # , title: params['title']
    end

    redirect_to checkouts_path(group: params[:group])
  end

  def confirm
    response = symphony_client.item_info(*params.require(:barcode))

    @item = Item.new(response)

    respond_to do |format|
      format.html do
        return render layout: false if request.xhr?
      end
    end
  end

  private

  def item_details
    { circRecordList: true }
  end

  def checkout_params
    params.require(:barcode)
  end
end
