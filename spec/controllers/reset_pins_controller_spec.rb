# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetPinsController do
  let(:mock_client) { instance_double(FolioClient, find_patron_by_barcode: patron, ping: true) }
  let(:patron) do
    instance_double(Folio::Patron, display_name: 'Patron', barcode: 'PATRON', email: 'patron@example.com',
                                   pin_reset_token: 'abcdef')
  end

  before do
    allow(ApplicationController).to receive(:ils_client_class).and_return(FolioClient)
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  context 'with an authenticated request' do
    before do
      warden.set_user(user)
    end

    let(:user) do
      { username: 'somesunetid', patron_key: '50e8400-e29b-41d4-a716-446655440000' }
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
      it 'sends the reset pin email' do
        expect { post :reset, params: { library_id: '123456' } }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'sets flash messages' do
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
      let(:mock_client) { instance_double(FolioClient, change_pin: {}, ping: true) }

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
      before do
        allow(mock_client).to receive(:change_pin).and_raise(FolioClient::IlsError)
      end

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
