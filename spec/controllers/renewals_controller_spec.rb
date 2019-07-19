# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RenewalsController, type: :controller do
  let(:api_response) { instance_double('Response', status: 200, content_type: :json) }
  let(:mock_client) { instance_double(SymphonyClient, renew_item: api_response) }
  let(:user) do
    { username: 'somesunetid', patron_key: '123' }
  end

  before do
    warden.set_user(user)
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
  end

  describe '#create' do
    it 'requires resource and item_key params' do
      expect { post :create, params: {} }.to raise_error(ActionController::ParameterMissing)
    end
    context 'when everything is good' do
      it 'renews the item and sets flash messages' do
        post :create, params: { resource: 'abc', item_key: '123' }
        puts 'yolo', response.status, response
        expect(flash[:success]).to match(/Success!/)
      end
      it 'renews the item and redirects to checkouts_path' do
        post :create, params: { resource: 'abc', item_key: '123' }
        expect(response).to redirect_to checkouts_path
      end
    end

    context 'when the response is not 200' do
      let(:api_response) { instance_double('Response', status: 401, content_type: :json) }

      it 'does not renew the item and sets flash messages' do
        post :create, params: { resource: 'abc', item_key: '123' }
        expect(flash[:error]).to match(/Sorry!/)
      end
      it 'does not renew the item and redirects to checkouts_path' do
        post :create, params: { resource: 'abc', item_key: '123' }
        expect(response).to redirect_to checkouts_path
      end
    end
  end
end
