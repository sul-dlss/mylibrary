# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinesController do
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

    it 'assigns a list of requests' do
      get(:index)

      expect(assigns(:fines)).to eq fines
    end

    it 'assigns a list of checkouts' do
      get(:index)

      expect(assigns(:checkouts)).to eq checkouts
    end
  end
end
