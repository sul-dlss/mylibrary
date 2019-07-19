# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinesController do
  let(:mock_patron) { instance_double(Patron) }

  let(:mock_legacy_client) do
    instance_double(
      SymphonyLegacyClient,
      payments: mock_legacy_client_response
    )
  end

  let(:mock_legacy_client_response) do
    '<LookupPatronInfoResponse>
      <feeInfo>
        <billNumber>1</billNumber>
       </feeInfo>
       <feeInfo>
        <billNumber>2</billNumber>
       </feeInfo>
    </LookupPatronInfoResponse>'
  end

  before do
    allow(controller).to receive(:patron).and_return(mock_patron)
    allow(controller).to receive(:symphony_client)
      .and_return(instance_double(SymphonyClient, session_token: '1a2b3c4d5e6f7g8h9i0j'))
    allow(SymphonyLegacyClient).to receive(:new).and_return(mock_legacy_client)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    let(:fines) do
      [
        instance_double(Fine, key: '1')
      ]
    end

    let(:checkouts) do
      [
        instance_double(Checkout, key: '2', due_date: Time.zone.now)
      ]
    end

    before do
      allow(mock_patron).to receive(:fines).and_return(fines)
      allow(mock_patron).to receive(:checkouts).and_return(checkouts)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of fines' do
      get(:index)

      expect(assigns(:fines)).to eq fines
    end

    it 'assigns a list of checkouts' do
      get(:index)

      expect(assigns(:checkouts)).to eq checkouts
    end

    context 'when a user has multiple payments' do
      it 'shows a list of payments from the payments array' do
        get(:index)

        expect(assigns(:payments)).to all(be_a Payment)
      end

      it 'shows the correct number of payments in the list' do
        get(:index)

        expect(assigns(:payments).length).to eq 2
      end
    end

    context 'when a user has only one payment' do
      let(:mock_legacy_client_response) do
        '<LookupPatronInfoResponse>
          <feeInfo>
           <billNumber>1</billNumber>
          </feeInfo>
        </LookupPatronInfoResponse>'
      end

      it 'wraps a single payment in an array' do
        get(:index)

        expect(assigns(:payments).first.key).to eq '1'
      end
    end
  end

  context 'with an authenticated request for group fines' do
    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    let(:fines) do
      [
        instance_double(Fine, key: '1')
      ]
    end

    let(:checkouts) do
      [
        instance_double(Checkout, key: '2', due_date: Time.zone.now)
      ]
    end

    before do
      allow(mock_patron).to receive(:group_fines).and_return(fines)
      allow(mock_patron).to receive(:group_checkouts).and_return(checkouts)
      warden.set_user(user)
    end

    it 'assigns a list of fines' do
      get(:index, params: { group: true })

      expect(assigns(:fines)).to eq fines
    end

    it 'assigns a list of checkouts' do
      get(:index, params: { group: true })

      expect(assigns(:checkouts)).to eq checkouts
    end
  end
end
