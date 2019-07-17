# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetPinsController, type: :controller do
  let(:mock_client) { instance_double(SymphonyClient, reset_pin: {}) }

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
  end

  context 'with an authenticated request' do
    before do
      warden.set_user(user)
    end

    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    it 'index logs out and redirects to the logout url' do
      expect(get(:index)).to redirect_to logout_url
    end

    it 'reset logs out and redirects to the logout url' do
      expect(post(:reset)).to redirect_to logout_url
    end
  end

  context 'with unauthenticated requests' do
    describe '#reset' do
      it 'resets the pin and sets flash messages' do
        post :reset, params: { library_id: '123456' }
        expect(flash[:success]).to match(/associated with library ID 123456/)
      end
    end
  end
end
