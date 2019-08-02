# frozen_string_literal: true

# Controller for handling CyberSource responses from payments.
#
# They send the user back with a POST request that contains
# information about the payment made (or canceled)
class PaymentsController < ApplicationController
  # CyberSource is posting back to our controller, so we don't
  # get an authenticity token that the cross-site request
  # forgery protection can use to validate the request
  skip_forgery_protection

  # The payment was accepted by CyberSource, but it may take a few moments
  # to reconcile the payment and have up-to-date information appear in
  # the Symphony API response.
  #
  # We include a `payment_pending` parameter to suppress some information
  # in the hope that, by the time the user refreshes the page, everything
  # will be consistent again.
  #
  # POST /payments/accept
  def accept
    redirect_to fines_path(payment_pending: true), flash: {
      success: (t 'mylibrary.fine_payment.accept_html', amount: params[:req_amount])
    }
  end

  # The user canceled the payment in CyberSource
  #
  # POST /payments/cancel
  def cancel
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.cancel_html') }
  end
end
