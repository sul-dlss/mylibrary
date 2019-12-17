# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinesController do
  let(:mock_patron) { instance_double(Patron, group?: false, barcode: '1234') }

  let(:fines) do
    [
      instance_double(Fine, key: '1', sequence: '1', owed: '12', status: 'BADCHECK')
    ]
  end

  before do
    allow(controller).to receive(:patron).and_return(mock_patron)
    allow(controller).to receive(:symphony_client)
      .and_return(instance_double(SymphonyClient, session_token: '1a2b3c4d5e6f7g8h9i0j', ping: true))
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
  end

  context 'with an authenticated request for group fines' do
    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    let(:checkouts) do
      [
        instance_double(Checkout, key: '2', due_date: Time.zone.now)
      ]
    end

    before do
      allow(mock_patron).to receive(:group).and_return(
        instance_double(Group, fines: fines, checkouts: checkouts)
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
