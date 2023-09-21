# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SummariesController do
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  let(:user) do
    { username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002' }
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    subject(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end

    before do
      allow(mock_client).to receive_messages(patron_info: patron_info)
      warden.set_user(user)
    end

    it 'redirects to the home page' do
      expect(get(:index)).to render_template 'index'
    end
  end

  context 'when there is no response from Folio' do
    before do
      allow(mock_client).to receive(:ping).and_return(false)
    end

    it 'redirects to a page that displays a message that the system is unavailable' do
      expect(get(:index)).to redirect_to unavailable_path
    end
  end
end
