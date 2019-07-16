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
  end
end
