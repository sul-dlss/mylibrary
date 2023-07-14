# frozen_string_literal: true

# Controller for handling CyberSource responses from payments.
#
# They send the user back with a POST request that contains
# information about the payment made (or canceled)
class PaymentsController < ApplicationController
  before_action :authenticate_user!, except: %i[accept cancel]
  # CyberSource is posting back to our controller, so we don't
  # get an authenticity token that the cross-site request
  # forgery protection can use to validate the request
  skip_forgery_protection only: %i[accept cancel]

  def index
    # @payments = payments.sort_by { |payment| payment.sort_key(:payment_date) }
    @payments = payments

    respond_to do |format|
      format.html { render }
      format.json { render json: payments_json_response }
    end
  end

  # Render a list of the payment histroy for the patron
  #
  # GET /payments
  # GET /payments.json
  def create
    set_payment_cookie
    redirect_to(controller: 'cybersource', action: 'create', params: create_payment_params.to_h)
  end

  # The payment was accepted by CyberSource, but it may take a few moments
  # to reconcile the payment and have up-to-date information appear in
  # the FOLIO API response.
  #
  # We include a `payment_pending` parameter to suppress some information
  # in the hope that, by the time the user refreshes the page, everything
  # will be consistent again.
  #
  # POST /payments/accept
  def accept
    alter_payment_cookie

    response = FolioClient.new.accounts_pay(params)
    Rails.logger.info("FOLIO BULK PAY RESPONSE STATUS: #{response['status']}")

    redirect_to fines_path, flash: {
      success: (t 'mylibrary.fine_payment.accept_html', amount: params[:req_amount])
    }
  end

  # The user canceled the payment in CyberSource
  #
  # POST /payments/cancel
  def cancel
    cookies.delete :payment_in_process
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.cancel_html') }
  end

  private

  # Formatted for use by the ajax_in_place_update library
  def payments_json_response
    {
      key: 'payments',
      type: 'async',
      html: render_to_string(formats: [:html], layout: false)
    }
  end

  ##
  # Sets a cookie with information from the payment so that we can understand
  # that there is a payment in flight
  def set_payment_cookie
    cookies[:payment_in_process] = {
      value: {
        billseq: create_payment_params[:billseq],
        session_id: create_payment_params[:session_id],
        group: create_payment_params[:group]
      }.to_json,
      httponly: true,
      expires: 10.minutes
    }
  end

  ##
  # On return from cybersource check the session_id to see if it checks out and
  # then set the payment as "pending"
  def alter_payment_cookie
    new_cookie = payment_in_process_cookie.dup
    new_cookie[:pending] = true if new_cookie[:session_id] == params[:req_merchant_defined_data2]
    cookies[:payment_in_process] = {
      value: new_cookie.to_json,
      httponly: true,
      expires: 10.minutes
    }
  end

  def payments
    # payments = ils_client.payments(patron)
    patron.payments
  end

  def create_payment_params
    params.permit(%I[reason billseq amount session_id user group key])
  end
end
