# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController do
  let(:user) { { username: 'somesunetid', patron_key: '123' } }

  before do
    allow(controller).to receive_messages(patron: mock_patron, ils_client: mock_client)
    warden.set_user(user)
  end

  # TODO: remove once migration is complete
  context 'when the ILS is symphony' do
    let(:mock_patron) { instance_double(Symphony::Patron, group?: false, barcode: '1234', payments: payments) }
    let(:mock_client) do
      instance_double(SymphonyClient, session_token: '1a2b3c4d5e6f7g8h9i0j', ping: true, pay_fines: nil)
    end
    let(:mock_legacy_client_response) do
      [
        { 'billNumber' => '1', 'feePaymentInfo' => { 'paymentDate' => '2019-01-01' } },
        { 'billNumber' => '2' },
        { 'billNumber' => '3', 'feePaymentInfo' => { 'paymentDate' => '2019-02-01' } }
      ]
    end
    let(:payments) do
      Array.wrap(mock_legacy_client_response).map do |x|
        Symphony::Payment.new(x)
      end
    end

    before do
      allow(mock_client).to receive(:is_a?).with(SymphonyClient).and_return(true)
    end

    describe '#index' do
      context 'when a user has multiple payments' do
        before do
          get(:index)
        end

        it 'shows a list of payments from the payments array' do
          expect(assigns(:payments)).to all(be_a Symphony::Payment)
        end

        it 'shows the correct number of payments in the list' do
          expect(assigns(:payments).length).to eq 3
        end

        it 'shows the payments sorted appropriately (bills w/o a payment date at the top the reverse date sort)' do
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

    describe '#create' do
      before do
        post :create, params: { user: 'u', billseq: 'b', session_id: 's', group: 'g', amount: 'a' }
      end

      it 'renders a form to send to cybersource' do
        expect(response).to render_template('cybersource_form')
      end

      it 'creates a cookie with needed information' do
        expect(JSON.parse(response.cookies['payment_in_process'])).to include(
          'billseq' => 'b',
          'session_id' => 's',
          'group' => 'g'
        )
      end
    end

    describe '#accept' do
      let(:cybersource_response) do
        instance_double(Cybersource::PaymentResponse, user: '123', amount: '10.00',
                                                      session_id: 'session_this_is_the_one',
                                                      valid?: true, payment_success?: true)
      end

      before do
        allow(controller).to receive(:cybersource_response).and_return(cybersource_response)
      end

      it 'updates the payment in the ILS' do
        post :accept
        expect(mock_client).to have_received(:pay_fines)
          .with(user: '123', amount: '10.00', session_id: 'session_this_is_the_one')
      end

      it 'redirects to fines page' do
        post :accept
        expect(controller).to redirect_to(fines_path)
      end

      it 'flashes a success message' do
        post :accept
        expect(flash[:success]).to include('Success!').and include('$10.00 paid.')
      end

      context 'when session_id matches cookie' do
        before do
          request.cookies['payment_in_process'] = {
            session_id: 'session_this_is_the_one'
          }.to_json
        end

        it 'sets pending in the new cookie' do
          post :accept
          expect(JSON.parse(response.cookies['payment_in_process'])).to include(
            'pending' => true,
            'session_id' => 'session_this_is_the_one'
          )
        end
      end

      context 'when the params sent back from cybersource do not pass validation' do
        before do
          allow(controller).to receive(:cybersource_response).and_raise(Cybersource::Security::InvalidSignature)
        end

        it 'flashes an error message' do
          post :accept
          expect(flash[:error]).to include('Payment failed.')
        end
      end

      context 'when cybersource rejected the payment' do
        before do
          allow(controller).to receive(:cybersource_response).and_raise(Cybersource::PaymentResponse::PaymentFailed)
        end

        it 'flashes an error message' do
          post :accept
          expect(flash[:error]).to include('Payment failed.')
        end
      end
    end

    describe '#cancel' do
      before do
        post :cancel
        request.cookies['payment_in_process'] = true
      end

      it 'redirects to index with no payment_pending param' do
        expect(controller).to redirect_to(fines_path)
      end

      it 'removes payment_in_process cookie' do
        expect(response.cookies['payment_in_process']).to be_nil
      end

      it 'flashes a cancellation message' do
        expect(flash[:error]).to include 'Payment canceled.'
      end
    end
  end

  context 'when the ILS is folio' do
    let(:mock_patron) { instance_double(Folio::Patron, group?: false, barcode: '1234', payments: payments) }
    let(:mock_client) { instance_double(FolioClient, ping: true, pay_fines: nil) }
    let(:mock_graphql_client_response) do
      [
        { 'id' => '1', 'actions' => [{ 'dateAction' => '2019-01-01' }, { 'dateAction' => '2019-01-02' }],
          'status' => { 'name' => 'Closed' } },
        { 'id' => '2', 'actions' => [{ 'dateAction' => '2019-01-15' }] },
        { 'id' => '3', 'actions' => [{ 'dateAction' => '2019-02-01' }, { 'dateAction' => '2019-02-03' }],
          'status' => { 'name' => 'Closed' } }
      ]
    end
    let(:payments) { mock_graphql_client_response.map { |record| Folio::Account.new(record) } }

    before do
      allow(mock_client).to receive(:is_a?).with(SymphonyClient).and_return(false)
    end

    describe '#index' do
      context 'when a user has multiple payments' do
        before do
          get(:index)
        end

        it 'shows a list of payments from the payments array' do
          expect(assigns(:payments)).to all(be_a Folio::Account)
        end

        it 'shows the correct number of payments in the list' do
          expect(assigns(:payments).length).to eq 3
        end

        it 'shows the payments sorted appropriately (bills w/o a payment date at the top the reverse date sort)' do
          expect(assigns(:payments).map(&:key)).to eq(%w[2 3 1])
        end
      end

      context 'when a user has only one payment' do
        let(:mock_graphql_client_response) do
          [{ 'id' => '1', 'actions' => [{ 'dateAction' => '2019-01-15' }] }]
        end

        it 'wraps a single payment in an array' do
          get(:index)
          expect(assigns(:payments).first.key).to eq '1'
        end
      end
    end

    describe '#create' do
      before do
        post :create, params: { user: 'u', session_id: 's', group: 'g', amount: 'a' }
      end

      it 'renders a form to send to cybersource' do
        expect(response).to render_template('cybersource_form')
      end
    end

    describe '#accept' do
      let(:cybersource_response) do
        instance_double(Cybersource::PaymentResponse, user: '123', amount: '10.00',
                                                      session_id: 'session_this_is_the_one',
                                                      valid?: true, payment_success?: true)
      end

      before do
        allow(controller).to receive(:cybersource_response).and_return(cybersource_response)
      end

      it 'updates the payment in the ILS' do
        post :accept
        expect(mock_client).to have_received(:pay_fines)
          .with(user: '123', amount: '10.00', session_id: 'session_this_is_the_one')
      end

      it 'redirects to fines page' do
        post :accept
        expect(controller).to redirect_to(fines_path)
      end

      it 'flashes a success message' do
        post :accept
        expect(flash[:success]).to include('Success!').and include('$10.00 paid.')
      end

      context 'when the params sent back from cybersource do not pass validation' do
        before do
          allow(controller).to receive(:cybersource_response).and_raise(Cybersource::Security::InvalidSignature)
        end

        it 'flashes an error message' do
          post :accept
          expect(flash[:error]).to include('Payment failed.')
        end
      end

      context 'when cybersource rejected the payment' do
        before do
          allow(controller).to receive(:cybersource_response).and_raise(Cybersource::PaymentResponse::PaymentFailed)
        end

        it 'flashes an error message' do
          post :accept
          expect(flash[:error]).to include('Payment failed.')
        end
      end
    end

    describe '#cancel' do
      before { post :cancel }

      it 'redirects to the fines page' do
        expect(controller).to redirect_to(fines_path)
      end

      it 'flashes a cancellation message' do
        expect(flash[:error]).to include 'Payment canceled.'
      end
    end
  end
end
