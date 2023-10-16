# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Feedback form' do
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
  end

  context 'when not logged in' do
    it 'reCAPTCHA challenge is present' do
      visit feedback_path
      expect(page).to have_css '.mylibrary-captcha'
    end
  end

  context 'without js' do
    before do
      login_as(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')

      visit root_path
    end

    it 'reCAPTCHA challenge is NOT present' do
      visit feedback_path
      expect(page).not_to have_css '.mylibrary-captcha'
    end

    it 'feedback form should be shown filled out and submitted' do
      click_link 'Feedback'
      expect(page).to have_css('#feedback-form', visible: :visible)
      expect(page).to have_link 'Cancel'
      within 'form.feedback-form' do
        fill_in('message', with: 'This is only a test')
        fill_in('name', with: 'Ronald McDonald')
        fill_in('to', with: 'test@kittenz.eu')
        click_button 'Send'
      end
      expect(page).to have_css('div.alert-success', text: 'Thank you! Your feedback has been sent.')
    end
  end
end
