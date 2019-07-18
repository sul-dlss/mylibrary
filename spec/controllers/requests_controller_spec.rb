# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsController do
  let(:mock_patron) { instance_double(Patron) }

  before do
    allow(controller).to receive(:patron).and_return(mock_patron)
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

    let(:requests) do
      [
        instance_double(Request, key: '1', expiration_date: Time.zone.now, fill_by_date: nil)
      ]
    end

    before do
      allow(mock_patron).to receive(:requests).and_return(requests)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of requests' do
      get(:index)

      expect(assigns(:requests)).to eq requests
    end
  end
end
