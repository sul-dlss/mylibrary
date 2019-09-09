# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal flash messages', type: :feature do
  let(:user) { '521181' }

  before do
    login_as(username: 'SUPER1', patron_key: user)
  end

  context 'when message is set' do
    before do
      Settings.internal_pages_flash_message_config = ['summaries']
      Settings.internal_pages_flash_message_html = '<p>Test message</p>'
    end

    it 'renders flash for a configured controller' do
      visit summaries_url
      within('div.alert') do
        expect(page).to have_css('p', text: 'Test message')
      end
    end

    it 'does not render flash for a non-configured controller' do
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
