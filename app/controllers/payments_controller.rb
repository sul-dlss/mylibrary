# frozen_string_literal: true

# Controller for Payments from CyberSource
class PaymentsController < ApplicationController
  # CyberSource is posting back to our controller
  skip_forgery_protection

  def accept
    redirect_to fines_path(payment_pending: true), flash: {
      success: (t 'mylibrary.fine_payment.success_html', amount: params[:req_amount])
    }
  end

  def cancel
    redirect_to fines_path, flash: { error: 'Payment canceled. No payment was made for the payable amount.' }
  end
end
