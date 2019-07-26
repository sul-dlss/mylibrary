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
    describe '#update' do
      let(:api_response) { instance_double('Response', status: 200, content_type: :json) }

      before do
        allow(SymphonyClient).to receive(:new).and_return(mock_client)
      end

      context 'when cancel param is sent' do
        let(:mock_client) { instance_double(SymphonyClient, cancel_hold: api_response) }

        it 'cancels the hold and sets the flash message' do
          patch :update, params: { resource: 'abc', id: '123', cancel: true }
          expect(flash[:success]).to match(/Success!.*was canceled/)
        end
      end

      context 'when pickup_library param is sent' do
        let(:mock_client) { instance_double(SymphonyClient, change_pickup_library: api_response) }

        it 'updates the pickup library and sets the flash message' do
          patch :update, params: { resource: 'abc', id: '123', pickup_library: 'Other library' }
          expect(flash[:success].first).to match(/Success!.*pickup location was updated/)
        end
      end

      context 'when not_needed_after param is sent' do
        let(:mock_client) { instance_double(SymphonyClient, not_needed_after: api_response) }

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
    end

    describe '#destroy' do
      let(:api_response) { instance_double('Response', status: 200, content_type: :json) }
      let(:mock_client) { instance_double(SymphonyClient, cancel_hold: api_response) }

      before do
        allow(SymphonyClient).to receive(:new).and_return(mock_client)
      end

      it 'requires resource and id params' do
        expect { delete :destroy, params: { id: '123' } }.to raise_error(ActionController::ParameterMissing)
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

      context 'when the response is not 200' do
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
  end

  context 'with an authenticated request for group requests' do
    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    let(:requests) do
      [
        instance_double(Request, key: '1', expiration_date: Time.zone.now, fill_by_date: nil)
      ]
    end

    before do
      allow(mock_patron).to receive(:group).and_return(instance_double(Group, requests: requests))
      warden.set_user(user)
    end

    it 'assigns a list of checkouts' do
      get(:index, params: { group: true })

      expect(assigns(:requests)).to eq requests
    end
  end
end
