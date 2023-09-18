# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsController do
  let(:mock_patron) { instance_double(Folio::Patron, requests: requests, key: '123') }
  let(:requests) { [] }
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  before do
    # TODO: Remove after setting default ILS Client to FolioClient
    allow(ApplicationController).to receive(:ils_client_class).and_return(FolioClient)
    # TODO: Remove after setting default patron model to Folio::Patron
    allow(Settings.ils).to receive(:patron_model).and_return('Folio::Patron')
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive(:patron_or_group).and_return(mock_patron)
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
        instance_double(Folio::Request, key: '1', sort_key: nil)
      ]
    end

    let(:mock_client) { instance_double(FolioClient, ping: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of requests' do
      get(:index)

      expect(assigns(:requests)).to eq requests
    end

    describe 'BorrowDirect requests' do
      let(:requests) do
        [
          instance_double(Folio::Request, key: '1', sort_key: nil),
          instance_double(BorrowDirectRequests::Request, key: 'sta-1', sort_key: nil)
        ]
      end

      it 'are returned along with normal requests' do
        get(:index)

        expect(assigns(:requests).length).to eq 2
      end
    end

    describe '#update' do
      let(:api_response) { instance_double('Response', status: 204, content_type: :json) }

      let(:requests) do
        [instance_double(Folio::Request, key: '123')]
      end

      let(:mock_client) { instance_double(FolioClient, ping: true) }

      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
      end

      context 'when cancel param is sent' do
        let(:mock_client) { instance_double(FolioClient, cancel_hold: api_response, ping: true) }

        it 'cancels the hold and sets the flash message' do
          patch :update, params: { resource: 'abc', id: '123', cancel: true }

          expect(flash[:success]).to match(/Success!.*was canceled/)
        end
      end

      context 'when service_point param is sent' do
        let(:mock_client) { instance_double(FolioClient, change_pickup_library: api_response, ping: true) }

        it 'updates the pickup library and sets the flash message' do
          patch :update, params: { resource: 'abc', id: '123', service_point: 'Other library' }

          expect(flash[:success].first).to match(/Success!.*pickup location was updated/)
        end
      end

      context 'when not_needed_after param is sent' do
        let(:mock_client) { instance_double(FolioClient, not_needed_after: api_response, ping: true) }

        it 'updates the not needed after and sets the flash message' do
          patch :update, params: { resource: 'abc', id: '123', not_needed_after: '1999/01/01' }

          expect(flash[:success].first).to match(/Success!.*not needed after date was updated/)
        end

        it 'does not update the not needed after if dates are not changed' do
          patch :update, params: {
            resource: 'abc', id: '123', not_needed_after: '1999/01/01', current_fill_by_date: '1999/01/01'
          }

          expect(flash[:success]).to eq []
        end
      end

      context 'with a group request' do
        let(:mock_client) { instance_double(FolioClient, change_pickup_library: api_response, ping: true) }

        it 'renews the item and redirects to checkouts_path' do
          patch :update, params: { resource: 'abc', id: '123', service_point: 'Other library', group: true }

          expect(response).to redirect_to requests_path(group: true)
        end
      end

      context 'when the requested item is not available to the patron' do
        it 'does not renew the item and sets flash messages' do
          patch :update, params: { resource: 'abc', id: 'some_made_up_item_key' }

          expect(flash[:error]).to match('An unexpected error has occurred')
        end

        it 'does not renew the item and redirects to checkouts_path' do
          patch :update, params: { resource: 'abc', id: 'some_made_up_item_key' }

          expect(response).to redirect_to requests_path
        end
      end
    end

    describe '#destroy' do
      let(:api_response) { instance_double('Response', status: 204, content_type: :json) }
      let(:mock_client) { instance_double(FolioClient, cancel_hold: api_response, ping: true) }

      let(:requests) do
        [instance_double(Folio::Request, key: '123')]
      end

      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
      end

      context 'when everything is good' do
        it 'cancels the hold and sets flash messages' do
          delete :destroy, params: { resource: 'abc', id: '123' }
          expect(flash[:success]).to match(/Success!/)
        end

        it 'cancels the hold and redirects to requests_path' do
          delete :destroy, params: { resource: 'abc', id: '123' }
          expect(response).to redirect_to requests_path
        end
      end

      context 'when the response is not 204' do
        let(:api_response) { instance_double('Response', status: 401, content_type: :json, body: 'foo') }

        it 'does not cancel the hold and sets flash messages' do
          delete :destroy, params: { resource: 'abc', id: '123' }
          expect(flash[:error]).to match(/Sorry!/)
        end

        it 'does not cancel the hold and redirects to checkouts_path' do
          delete :destroy, params: { resource: 'abc', id: '123' }
          expect(response).to redirect_to requests_path
        end
      end
    end

    context 'with a group request' do
      it 'renews the item and redirects to checkouts_path' do
        delete :destroy, params: { resource: 'abc', id: '123', group: true }

        expect(response).to redirect_to requests_path(group: true)
      end
    end

    context 'when the requested item is not avaiable to the patron' do
      it 'does not renew the item and sets flash messages' do
        delete :destroy, params: { resource: 'abc', id: 'some_made_up_item_key' }

        expect(flash[:error]).to match('An unexpected error has occurred')
      end

      it 'does not renew the item and redirects to checkouts_path' do
        delete :destroy, params: { resource: 'abc', id: 'some_made_up_item_key' }

        expect(response).to redirect_to requests_path
      end
    end
  end

  context 'with an authenticated request for group requests' do
    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    let(:requests) do
      [
        instance_double(Folio::Request, key: '1', sort_key: nil)
      ]
    end

    let(:mock_client) { instance_double(FolioClient, ping: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
      warden.set_user(user)
    end

    it 'assigns a list of checkouts' do
      get(:index, params: { group: true })

      expect(assigns(:requests)).to eq requests
    end
  end
end
