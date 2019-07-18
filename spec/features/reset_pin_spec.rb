# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset Pin', type: :feature do
  context 'when logged in' do
    before do
      login_as(username: 'SUPER2', patron_key: '521182')
    end

    it 'logs out user and redirects to root' do
      visit reset_pin_path
      expect(page).to have_css 'h1', text: 'Log in to your library account'
    end
  end

  context 'when logged out' do
    it 'allows user to reset pin' do
      visit reset_pin_path
      fill_in('library_id', with: '123456')
      click_button 'Reset/Request PIN'
      expect(page).to have_css '.flash_messages', text: 'Check your email!'
    end
    it 'a user can change their pin' do
      visit change_pin_with_token_path('foo')
      fill_in('pin', with: '123456')
      click_button 'Change PIN'
      expect(page).to have_css '.flash_messages', text: 'Success!'
    end
  end

  describe 'show/hide password', js: true do
    it 'by default the field is a password type' do
      visit change_pin_with_token_path('foo')
      expect(page).to have_css '[type="password"]'
    end
    it 'can be shown by clicking show/hide button' do
      visit change_pin_with_token_path('foo')
      within '#main form' do
        first('[data-visibility]').click
        expect(page).to have_css '[type="text"]'
      end
    end
  end
end
