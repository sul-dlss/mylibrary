# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController do
  let(:user) { { username: 'somesunetid', patron_key: '123' } }

  describe '#index' do
    let(:mock_patron) { instance_double(Symphony::Patron, group?: false, barcode: '1234') }
    let(:mock_legacy_client) do
      instance_double(
        SymphonyLegacyClient,
        payments: mock_legacy_client_response
      )
    end
    let(:mock_legacy_client_response) do
      [
        { 'billNumber' => '1', 'feePaymentInfo' => { 'paymentDate' => '2019-01-01' } },
        { 'billNumber' => '2' },
        { 'billNumber' => '3', 'feePaymentInfo' => { 'paymentDate' => '2019-02-01' } }
      ]
    end

    before do
      allow(controller).to receive(:patron).and_return(mock_patron)
      allow(controller).to receive(:symphony_client)
        .and_return(instance_double(SymphonyClient, session_token: '1a2b3c4d5e6f7g8h9i0j', ping: true))
      allow(SymphonyLegacyClient).to receive(:new).and_return(mock_legacy_client)
    end

    context 'when an unathenticated user' do
      it 'redirects to the home page' do
        expect(get(:index)).to redirect_to root_url
      end
    end

    context 'with an authenticated user' do
      before { warden.set_user(user) }

      context 'when a user has multiple payments' do
        it 'shows a list of payments from the payments array' do
          get(:index)

          expect(assigns(:payments)).to all(be_a Symphony::Payment)
        end

        it 'shows the correct number of payments in the list' do
          get(:index)

          expect(assigns(:payments).length).to eq 3
        end

        it 'shows the payments sorted appropriately (bills w/o a payment date at the top the reverse date sort)' do
          get(:index)

          expect(assigns(:payments).map(&:key)).to eq(%w[2 3 1])
        end
      end

      context 'when a user has only one payment' do
        let(:mock_legacy_client_response) do
          { 'billNumber' => '1' }
        end

        it 'wraps a single payment in an array' do
          get(:index)

          expect(assigns(:payments).first.key).to eq '1'
        end
      end
    end
  end

  describe '#create' do
    let(:mock_client) { instance_double(SymphonyClient, ping: true) }

    before do
      allow(SymphonyClient).to receive(:new).and_return(mock_client)
      warden.set_user(user)
    end

    it 'redirects to payment system' do
      post :create
      expect(controller).to redirect_to 'https://example.com/secureacceptance/payment_form.php?'
    end

    it 'creates a cookie with needed information' do
      post :create, params: { billseq: 'b', session_id: 's', group: 'g' }
      expect(JSON.parse(response.cookies['payment_in_process'])).to include(
        'billseq' => 'b',
        'session_id' => 's',
        'group' => 'g'
      )
    end

    it 'passes through parameters' do
      post :create, params: { reason: 'r', billseq: 'b', amount: 'a', session_id: 's', user: 'u', group: 'g' }
      expect(controller).to redirect_to 'https://example.com/secureacceptance/payment_form.php?amount=a&billseq=b&group=g&reason=r&session_id=s&user=u'
    end
  end

  context 'when a user makes a payment' do
    context 'when session_id matches cookie' do
      let(:mock_client) { instance_double(SymphonyClient, ping: true) }

      before do
        allow(SymphonyClient).to receive(:new).and_return(mock_client)
        warden.set_user(user)
        request.cookies['payment_in_process'] = {
          session_id: 'session_this_is_the_one'
        }.to_json
        post :accept, params: { req_amount: '10.00', req_merchant_defined_data2: 'session_this_is_the_one' }
      end

      it 'sets pending in the new cookie' do
        expect(JSON.parse(response.cookies['payment_in_process'])).to include(
          'pending' => true,
          'session_id' => 'session_this_is_the_one'
        )
      end
    end

    context 'when indifferent of the cookie' do
      let(:mock_client) { instance_double(SymphonyClient, ping: true) }

      before do
        allow(SymphonyClient).to receive(:new).and_return(mock_client)
        warden.set_user(user)
        post :accept, params: { req_amount: '10.00' }
      end

      it 'redirects to fines' do
        expect(controller).to redirect_to(fines_path)
      end

      it 'flashes a success message' do
        expect(flash[:success]).to eq '<span class="font-weight-bold">Success!</span> $10.00 paid. ' \
                                      'A receipt has been sent to the email address associated with your account. ' \
                                      'Payment may take up to 5 minutes to appear in your payment history.'
      end
    end
  end

  context 'when a user cancels a payment' do
    let(:mock_client) { instance_double(SymphonyClient, ping: true) }

    before do
      allow(SymphonyClient).to receive(:new).and_return(mock_client)
      warden.set_user(user)
      post :cancel
      request.cookies['payment_in_process'] = true
    end

    it 'redirects to index with no payment_pending param' do
      expect(controller).to redirect_to(fines_path)
    end

    it 'removes payment_in_process cookie' do
      expect(response.cookies['payment_in_process']).to be_nil
    end

    it 'flashes an error message' do
      expect(flash[:error]).to eq '<span class="font-weight-bold">Payment canceled.</span> No payment was made ' \
                                  '&mdash; your payable balance remains unchanged.'
    end
  end
end
