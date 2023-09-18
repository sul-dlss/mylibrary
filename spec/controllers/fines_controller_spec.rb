# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinesController do
  let(:mock_patron) { instance_double(Folio::Patron, group?: false, barcode: '1234') }

  let(:fines) do
    [
      instance_double(Folio::Account, key: '1', sequence: '1', owed: '12', status: 'BADCHECK')
    ]
  end

  before do
    allow(controller).to receive_messages(patron: mock_patron,
                                          ils_client: instance_double(
                                            FolioClient, session_token: '1a2b3c4d5e6f7g8h9i0j', ping: true
                                          ))
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:user) do
      { username: 'somesunetid', patron_key: '50e8400-e29b-41d4-a716-446655440000' }
    end

    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '2', sort_key: Time.zone.now)
      ]
    end

    before do
      allow(mock_patron).to receive_messages(fines: fines, checkouts: checkouts)
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
  end

  context 'with an authenticated request for group fines' do
    let(:user) do
      { username: 'somesunetid', patron_key: '50e8400-e29b-41d4-a716-446655440000' }
    end

    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '2', sort_key: Time.zone.now)
      ]
    end

    before do
      allow(mock_patron).to receive(:group).and_return(
        instance_double(Folio::Group, fines: fines, checkouts: checkouts)
      )
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
