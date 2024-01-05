# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal flash messages' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron_info) do
    {
      'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
      'loans' => [],
      'holds' => [],
      'accounts' => []
    }
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_messages(patron_info:)
    login_as(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')
  end

  context 'when message is set' do
    before do
      Settings.internal_pages_flash_message_config = ['summaries']
      Settings.internal_pages_flash_message_html = '<p>Test message</p>'
    end

    it 'renders flash for a configured controller' do
      visit summaries_url
      within('.flash_messages div.alert') do
        expect(page).to have_css('p', text: 'Test message')
      end
    end

    it 'does not render flash for a non-configured controller' do
      visit requests_url
      expect(page).to have_no_css('p', text: 'Test message')
    end
  end

  context 'when message is not set' do
    before do
      Settings.internal_pages_flash_message_config = []
      Settings.internal_pages_flash_message_html = nil
    end

    it 'does not render flash if set message is empty' do
      visit summaries_url
      expect(page).to have_no_css('p', text: 'Test message')
    end
  end
end
