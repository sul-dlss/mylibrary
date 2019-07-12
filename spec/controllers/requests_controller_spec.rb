# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsController do
  let(:mock_client) { instance_double(SymphonyClient) }

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
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

    let(:mock_response) do
      {
        fields: {
          holdRecordList: [{ key: 1 }]
        }
      }.with_indifferent_access
    end

    before do
      allow(mock_client).to receive(:requests).with('123').and_return(mock_response)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of requests' do
      get(:index)

      expect(assigns(:requests)).to include a_kind_of(Request).and(have_attributes(key: 1))
    end
  end
end
