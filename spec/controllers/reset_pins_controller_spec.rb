# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetPinsController, type: :controller do
  let(:mock_client) { instance_double(SymphonyClient, reset_pin: {}, ping: true) }

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

  describe '#change' do
    it 'requires token and pin params' do
      expect { post :change, params: {} }.to raise_error(ActionController::ParameterMissing)
    end

    context 'when everything is good' do
      let(:response) { instance_double(Response, status: 200, content_type: :json) }
      let(:mock_client) { instance_double(SymphonyClient, change_pin: response, ping: true) }

      it 'changes the pin and sets flash messages' do
        post :change, params: { token: 'abc', pin: '123' }
        expect(flash[:success]).to match(/Success!/)
      end

      it 'changes the pin and redirects to login' do
        post :change, params: { token: 'abc', pin: '123' }
        expect(response).to redirect_to login_path
      end
    end

    context 'when the response is not 200' do
      let(:response) { instance_double(Response, status: 401, content_type: :json) }
      let(:mock_client) { instance_double(SymphonyClient, change_pin: response, ping: true) }

      it 'does not change the pin and sets flash messages' do
        post :change, params: { token: 'abc', pin: '123' }
        expect(flash[:error]).to match(/Sorry!/)
      end

      it 'does not change the pin and redirects to reset_pin' do
        post :change, params: { token: 'abc', pin: '123' }
        expect(response).to redirect_to reset_pin_path
      end
    end
  end
end
