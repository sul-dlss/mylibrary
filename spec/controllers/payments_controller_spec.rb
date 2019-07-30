# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController do
  context 'when a user makes a payment' do
    before do
      post :accept, params: { req_amount: '10.00' }
    end

    it 'redirects to index with payment_pending param' do
      expect(controller).to redirect_to('/fines?payment_pending=true')
    end

    it 'flashes a success message' do
      expect(flash[:success]).to eq '<span class="font-weight-bold">Success!</span> $10.00 paid. '\
                                                'A receipt was sent to the email on your account. ' \
                                                'Payment may take up to 5 minutes to appear in your payment history.'
    end
  end

  context 'when a user cancels a payment' do
    before do
      post :cancel
    end

    it 'redirects to index with no payment_pending param' do
      expect(controller).to redirect_to(fines_path)
    end

    it 'flashes an error message' do
      expect(flash[:error]).to eq '<span class="font-weight-bold">Payment Canceled.</span> No payment was made '\
                                          '-- your payable balance remains unchanged.'
    end
  end
end
