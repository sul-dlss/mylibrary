# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Feedback form' do
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
  end

  context 'when not logged in' do
    it 'reCAPTCHA challenge is present' do
      visit feedback_path
      expect(page).to have_css '.mylibrary-captcha'
    end
  end

  context 'with js', :js do
    before do
      login_as(username: 'SUPER1', patron_key: '50e8400-e29b-41d4-a716-446655440000')
      visit root_path
    end

    it 'feedback form should be hidden' do
      expect(page).not_to have_css('#feedback-form', visible: :visible)
    end

    it 'feedback form should be shown filled out and submitted' do
      click_link 'Feedback'
      skip('Passes locally, not on Travis.') if ENV['CI']
      expect(page).to have_css('#feedback-form', visible: :visible)
      expect(page).to have_button 'Cancel'
      within 'form.feedback-form' do
        fill_in('message', with: 'This is only a test')
        fill_in('name', with: 'Ronald McDonald')
        fill_in('to', with: 'test@kittenz.eu')
        click_button 'Send'
      end
      expect(page).to have_css('div.alert-success', text: 'Thank you! Your feedback has been sent.')
    end
  end

  context 'without js' do
    before do
      login_as(username: 'SUPER1', patron_key: '50e8400-e29b-41d4-a716-446655440000')

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
