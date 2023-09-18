# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal flash messages' do
  let(:mock_client) { instance_double(FolioClient, find_patron_by_barcode: patron, ping: true) }
  let(:patron) do
    instance_double(Folio::Patron, display_name: 'Patron', barcode: 'PATRON', email: 'patron@example.com')
  end
  let(:mock_response) do
    {
      'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
      'loans' => [],
      'holds' => [],
      'accounts' => []
    }.with_indifferent_access
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:patron_info).with('50e8400-e29b-41d4-a716-446655440000',
                                                     item_details: {}).and_return(mock_response)
    login_as(username: 'SUPER1', patron_key: '50e8400-e29b-41d4-a716-446655440000')
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
      allow(mock_client).to receive(:patron_info).with('50e8400-e29b-41d4-a716-446655440000',
                                                       item_details: { holdRecordList: true }).and_return(mock_response)
      visit requests_url
      expect(page).not_to have_css('p', text: 'Test message')
    end
  end

  context 'when message is not set' do
    before do
      Settings.internal_pages_flash_message_config = []
      Settings.internal_pages_flash_message_html = nil
    end

    it 'does not render flash if set message is empty' do
      visit summaries_url
      expect(page).not_to have_css('p', text: 'Test message')
    end
  end
end
