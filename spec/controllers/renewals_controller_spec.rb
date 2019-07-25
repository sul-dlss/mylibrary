# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RenewalsController, type: :controller do
  let(:api_response) { instance_double('Response', status: 200, content_type: :json) }
  let(:mock_client) do
    instance_double(SymphonyClient, renew_item: api_response)
  end
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

  describe '#all_eligible' do
    let(:mock_client) do
      instance_double(SymphonyClient, renew_items: api_response)
    end
    let(:api_response) { { success: ['Success!'], error: ['Sorry!'] } }
    let(:mock_patron) { instance_double(Patron, checkouts: checkouts) }
    let(:checkouts) do
      [
        instance_double(Checkout, key: '1', renewable?: true, item_key: '123', title: 'ABC', resource: 'item'),
        instance_double(Checkout, key: '2', renewable?: true, item_key: '456', title: 'XYZ', resource: 'item'),
        instance_double(Checkout, key: '3', renewable?: false, item_key: '789', title: 'Not', resource: 'item')
      ]
    end

    before do
      allow(controller).to receive(:patron).and_return(mock_patron)
    end

    it 'sends renewal requests to symphony for eligible items' do
      post :all_eligible

      expect(mock_client).to have_received(:renew_items).with([
                                                                having_attributes(key: '1'),
                                                                having_attributes(key: '2')
                                                              ])
    end

    it 'sets a success flash message' do
      post :all_eligible

      expect(flash[:success]).to include(/Success!/)
    end

    it 'sets an reror flash message' do
      post :all_eligible

      expect(flash[:error]).to include(/Sorry!/)
    end

    it 'renews the item and redirects to checkouts_path' do
      post :all_eligible

      expect(response).to redirect_to checkouts_path
    end
  end
end
