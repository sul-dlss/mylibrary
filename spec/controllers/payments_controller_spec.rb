# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController do
  describe '#index' do
    let(:mock_fine) do
      [
        {
          'id' => '1',
          'item' => nil,
          'amount' => 75,
          'dateCreated' => nil,
          'feeFineId' => '116f8665-4ba5-4c14-8c0e-36c41e961381',
          'feeFineType' => 'lost item',
          'paymentStatus' => {
            'name' => 'Paid fully'
          }
        },
        {
          'id' => '2',
          'item' => nil,
          'amount' => 15,
          'dateCreated' => nil,
          'feeFineId' => '2769c09d-c2e8-4a40-9601-48f95a14a395',
          'feeFineType' => 'damage to material',
          'paymentStatus' => {
            'name' => 'Paid fully'
          }
        },
        {
          'id' => '3',
          'item' => nil,
          'amount' => 10,
          'dateCreated' => nil,
          'feeFineId' => '116f8665-4ba5-4c14-8c0e-36c41e961381',
          'feeFineType' => 'lost item',
          'paymentStatus' => {
            'name' => 'Waived fully'
          }
        },
        {
          'id' => '4',
          'item' => nil,
          'amount' => 2,
          'dateCreated' => nil,
          'feeFineId' => 'd90d6659-2ed4-41ba-a23e-8e29e9d632e7',
          'feeFineType' => 'short term fine',
          'paymentStatus' => {
            'name' => 'Outstanding'
          }
        }
      ]
    end

    let(:user) { { username: 'somesunetid', patron_key: '123', 'accounts' => mock_fine } }

    let(:mock_patron) { instance_double(Folio::Patron, group?: false, barcode: '1234', 'accounts' => mock_fine) }

    let(:mock_client) { instance_double(FolioClient, patron_info: user, ping: true) }

    before do
      stub_request(:post, 'https://example.com/authn/login')
        .to_return(headers: { 'x-okapi-token': 'tokentokentoken' })

      allow(controller).to receive(:ils_client).and_return(mock_client)
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

          expect(assigns(:payments).first).to be_a Folio::Fine
        end

        it 'shows the correct number of payments in the list' do
          get(:index)

          expect(assigns(:payments).length).to eq 4
        end

        it 'shows the payments sorted appropriately (bills w/o a payment date at the top the reverse date sort)' do
          get(:index)

          payments = assigns(:payments).compact
          expect(payments.map(&:sequence)).to eq(%w[1 2])
        end
      end

      context 'when a user has only one payment' do
        it 'wraps a single payment in an array' do
          get(:index)

          expect(assigns(:payments).first.sequence).to eq '1'
        end
      end
    end
  end

  describe '#create' do
    let(:user) { { username: 'somesunetid', patron_key: '123' } }
    let(:mock_client) { instance_double(FolioClient, patron_info: user, ping: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
      warden.set_user(user)
    end

    it 'redirects to payment controller' do
      post :create
      expect(controller).to redirect_to controller: 'cybersource', action: 'create'
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
      expect(controller).to redirect_to controller: 'cybersource', action: 'create', amount: 'a', billseq: 'b',
                                        group: 'g', reason: 'r', session_id: 's', user: 'u'
    end
  end

  context 'when a user makes a payment' do
    context 'when session_id matches cookie' do
      let(:user) { { username: 'somesunetid', patron_key: '123' } }
      let(:mock_client) { instance_double(FolioClient, patron_info: user, ping: true) }

      before do
        warden.set_user(user)
        allow(mock_client).to receive(:accounts_pay).and_return([status: 201])

        request.cookies['payment_in_process'] = {
          session_id: 'session_this_is_the_one'
        }.to_json

        stub_request(:post, 'http://example.com/authn/login')
          .with(
            body: '{"username":null,"password":null}',
            headers: {
              'Accept' => 'application/json, text/plain',
              'X-Okapi-Tenant' => 'sul'
            }
          ).to_return(status: 201)

        post :accept,
             params: { req_amount: '10.00', req_merchant_defined_data1: 'abc|123',
                       req_merchant_defined_data2: 'session_this_is_the_one' }
      end

      xit 'sets pending in the new cookie' do
        expect(JSON.parse(response.cookies['payment_in_process'])).to include(
          'pending' => true,
          'session_id' => 'session_this_is_the_one'
        )
      end
    end

    context 'when indifferent of the cookie' do
      let(:user) { { username: 'somesunetid', patron_key: '123' } }
      let(:mock_client) { instance_double(FolioClient, patron_info: user, ping: true) }

      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:accounts_pay).and_return(status: 200)
        warden.set_user(user)

        stub_request(:post, 'http://example.com/accounts-bulk/pay')
          .with(body: Settings.okapi.login_params.to_h)
          .to_return(status: 200)

        post :accept, params: { req_amount: '10.00', req_merchant_defined_data1: 'abc|123' }
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
    let(:user) { { username: 'somesunetid', patron_key: '123' } }
    let(:mock_client) { instance_double(FolioClient, patron_info: user, ping: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
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
