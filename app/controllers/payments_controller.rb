# frozen_string_literal: true

# Controller for handling payment of fines.
class PaymentsController < ApplicationController
  before_action :authenticate_user!

  # Cybersource is POSTing back to our controller, so we don't
  # get an authenticity token that the cross-site request
  # forgery protection can use to validate the request
  skip_forgery_protection only: %i[accept cancel]

  rescue_from Cybersource::Security::InvalidSignature,
              Cybersource::PaymentResponse::PaymentFailed, with: :payment_failed
  rescue_from FolioClient::IlsError, SymphonyClient::IlsError, with: :ils_request_failed

  # Render the payment history page
  #
  # GET /payments
  # GET /payments.json
  def index
    @payments = patron_or_group.payments.sort_by { |payment| payment.sort_key(:payment_date) }

    respond_to do |format|
      format.html { render }
      format.json { render json: payments_json_response }
    end
  end

  # Send the user to Cybersource to make a payment via an interstitial form
  #
  # POST /payments
  def create
    set_payment_cookie
    @params = cybersource_request

    render 'cybersource_form', layout: false
  end

  # The payment was accepted by Cybersource, so update the fines in the ILS
  #
  # POST /payments/accept
  def accept
    alter_payment_cookie
    ils_client.pay_fines(user: cybersource_response.user,
                         amount: cybersource_response.amount,
                         session_id: cybersource_response.session_id)

    redirect_to fines_path, flash: {
      success: (t 'mylibrary.fine_payment.accept_html', amount: cybersource_response.amount)
    }
  end

  # The user canceled the payment in Cybersource
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
    new_cookie[:pending] = true if new_cookie[:session_id] == cybersource_response.session_id
    cookies[:payment_in_process] = {
      value: new_cookie.to_json,
      httponly: true,
      expires: 10.minutes
    }
  end

  def create_payment_params
    params.permit(%I[reason billseq amount session_id user group])
  end

  def cybersource_request
    Cybersource::PaymentRequest.new(**params.permit(:user, :amount, :session_id).to_h.symbolize_keys).sign!
  end

  def cybersource_response
    Cybersource::PaymentResponse.new(params.permit!.to_h).validate!
  end

  def payment_failed
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.payment_failed_html') }
  end

  def ils_request_failed
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.request_failed_html') }
  end
end
