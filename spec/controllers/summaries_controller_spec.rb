# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SummariesController do
  let(:mock_client) { instance_double(SymphonyClient, ping: true) }

  let(:user) do
    { username: 'somesunetid', patron_key: '123' }
  end

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:mock_response) do
      {
        fields: {
          circRecordList: [{ key: 1 }]
        }
      }.with_indifferent_access
    end

    before do
      allow(mock_client).to receive(:patron_info).with('123', item_details: {}).and_return(mock_response)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end
  end

  context 'when there is no response from symphony' do
    before do
      allow(mock_client).to receive(:ping).and_return(false)
    end

    it 'redirects to a page that displays a message that the system is unavailable' do
      expect(get(:index)).to redirect_to unavailable_path
    end
  end
end
