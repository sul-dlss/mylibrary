# frozen_string_literal: true

# Controller for Payments from CyberSource
class PaymentsController < ApplicationController
  # CyberSource is posting back to our controller
  skip_forgery_protection

  def accept
    redirect_to fines_path(payment_pending: true), flash: {
      success: (t 'mylibrary.fine_payment.accept_html', amount: params[:req_amount])
    }
  end

  def cancel
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.cancel_html') }
  end
end
