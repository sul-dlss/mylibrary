# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutsController do
  let(:mock_patron) { instance_double(Folio::Patron) }

  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:requests) { [] }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive(:patron).and_return(mock_patron)
    allow(mock_patron).to receive(:requests).and_return(requests)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:user) do
      User.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')
    end

    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '1', sort_key: nil)
      ]
    end

    before do
      allow(mock_patron).to receive(:checkouts).and_return(checkouts)
      warden.set_user(user)
    end

    it 'displays list of checkouts' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of checkouts' do
      get(:index)

      expect(assigns(:checkouts)).to eq checkouts
    end

    context 'with requests' do
      let(:requests) do
        [
          instance_double(Folio::Request, key: '1', sort_key: nil)
        ]
      end

      it 'assigns the requests' do
        get(:index)

        expect(assigns(:requests)).to eq requests
      end
    end
  end

  context 'with an authenticated request for group checkouts' do
    let(:user) do
      User.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')
    end

    let(:checkouts) do
      [
        instance_double(Folio::Checkout, key: '2', sort_key: nil)
      ]
    end

    before do
      allow(mock_patron).to receive(:group).and_return(instance_double(Folio::Group, checkouts:,
                                                                                     requests:))
      warden.set_user(user)
    end

    it 'assigns a list of checkouts' do
      get(:index, params: { group: true })

      expect(assigns(:checkouts)).to eq checkouts
    end
  end
end
