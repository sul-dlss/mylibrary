# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RenewalsController, type: :controller do
  let(:api_response) { instance_double(Response, status: 200, content_type: :json) }
  let(:mock_client) do
    instance_double(SymphonyClient, renew_item: api_response, ping: true)
  end
  let(:user) do
    { username: 'somesunetid', patron_key: '123' }
  end

  let(:mock_patron) { instance_double(Patron, checkouts: checkouts) }
  let(:checkouts) { [instance_double(Checkout, item_key: '123', item_category_non_renewable?: false)] }

  before do
    warden.set_user(user)
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive(:patron_or_group).and_return(mock_patron)
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
      let(:api_response) { instance_double(Response, status: 401, content_type: :json) }

      it 'does not renew the item and sets flash messages' do
        post :create, params: { resource: 'abc', item_key: '123' }

        expect(flash[:error]).to match(/Sorry!/)
      end

      it 'does not renew the item and redirects to checkouts_path' do
        post :create, params: { resource: 'abc', item_key: '123' }

        expect(response).to redirect_to checkouts_path
      end
    end

    context 'with a group request' do
      it 'renews the item and redirects to checkouts_path' do
        post :create, params: { resource: 'abc', item_key: '123', group: true }

        expect(response).to redirect_to checkouts_path(group: true)
      end
    end

    context 'when the requested item is not checked out to the patron' do
      it 'does not renew the item and sets flash messages' do
        post :create, params: { resource: 'abc', item_key: 'some_made_up_item_key' }

        expect(flash[:error]).to match('An unexpected error has occurred')
      end

      it 'does not renew the item and redirects to checkouts_path' do
        post :create, params: { resource: 'abc', item_key: 'some_made_up_item_key' }

        expect(response).to redirect_to checkouts_path
      end
    end

    context 'when the requested item is not eligible even though symphony does not stop us' do
      let(:checkouts) { [instance_double(Checkout, item_key: '123', item_category_non_renewable?: true)] }

      it 'does not renew the item and sets flash messages' do
        post :create, params: { resource: 'abc', item_key: '123' }

        expect(flash[:error]).to match('An unexpected error has occurred')
      end
    end
  end

  describe '#all_eligible' do
    let(:mock_client) do
      instance_double(SymphonyClient, renew_items: api_response, ping: true)
    end
    let(:api_response) { { success: [checkouts[0]], error: [checkouts[1]] } }
    let(:mock_patron) { instance_double(Patron, checkouts: checkouts) }
    let(:checkouts) do
      [
        instance_double(Checkout, key: '1', renewable?: true, item_key: '123', title: 'ABC', resource: 'item'),
        instance_double(Checkout, key: '2', renewable?: true, item_key: '456', title: 'XYZ', resource: 'item'),
        instance_double(Checkout, key: '3', renewable?: false, item_key: '789', title: 'Not', resource: 'item')
      ]
    end

    it 'sends renewal requests to symphony for eligible items' do
      post :all_eligible

      expect(mock_client).to have_received(:renew_items).with([
                                                                having_attributes(key: '1'),
                                                                having_attributes(key: '2')
                                                              ])
    end

    context 'when successful' do
      before { post :all_eligible }

      it 'sets a success flash message' do
        expect(flash[:success]).to include('Success!')
      end

      it 'includes the titles of successful renewals' do
        expect(Capybara.string(flash[:success])).to have_css('li', text: 'ABC')
      end
    end

    describe 'when unsuccessful' do
      before { post :all_eligible }

      it 'sets an error flash message' do
        expect(flash[:error]).to include('Sorry!')
      end

      it 'includes the titles of errored renewals' do
        expect(Capybara.string(flash[:error])).to have_css('li', text: 'XYZ')
      end
    end

    it 'renews the item and redirects to checkouts_path' do
      post :all_eligible

      expect(response).to redirect_to checkouts_path
    end
  end
end
