# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset Pin' do
  context 'when logged in' do
    before do
      login_as(username: 'SUPER2', patron_key: '521182')
    end

    it 'logs out user and redirects to root' do
      visit reset_pin_path
      expect(page).to have_css 'h1', text: 'Log in to see your checkouts, requests, fines & fees'
    end
  end

  context 'when using Symphony' do
    let(:mock_client) { instance_double(SymphonyClient, ping: true) }

    before do
      allow(Settings.ils).to receive(:client).and_return('SymphonyClient')
      allow(Settings.ils).to receive(:patron_model).and_return('Symphony::Patron')
      allow(SymphonyClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:reset_pin).and_return(nil)
      allow(mock_client).to receive(:change_pin).and_return(nil)
    end

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

  context 'when using FOLIO' do
    let(:client) { FolioClient.new(url: 'http://example.com') }
    let(:mock_client) { instance_double(FolioClient, ping: true) }
    let(:patron) do
      instance_double(Folio::Patron, key: 'abcdefg123', barcode: '123456', email: 'jdoe@stanford.edu',
                                     display_name: 'J Doe')
    end

    before do
      allow(Settings.ils).to receive(:client).and_return('FolioClient')
      allow(Settings.ils).to receive(:patron_model).and_return('Folio::Patron')
      allow(FolioClient).to receive(:new).and_return(client)
      allow(client).to receive(:session_token).and_return('token')
      allow(client).to receive(:find_patron_by_barcode).with('123456').and_return(patron)
    end

    it 'sends the user an email that can be used to change their pin' do
      visit reset_pin_path
      fill_in('library_id', with: '123456')
      click_button 'Reset/Request PIN'
      mail = ActionMailer::Base.deliveries.last
      token = mail.html_part.body.decoded.match(%r{change_pin/(.*?)">})[1]
      visit change_pin_with_token_path(token)
      fill_in('pin', with: 'newpin')
      click_button 'Change PIN'
      expect(page).to have_css '.flash_messages', text: 'Success!'
    end

    context 'when the token is invalid' do
      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:change_pin).and_raise(ActiveSupport::MessageEncryptor::InvalidMessage)
      end

      it 'shows the user an error' do
        visit change_pin_with_token_path('not_a_real_token')
        fill_in('pin', with: 'newpin')
        click_button 'Change PIN'
        expect(page).to have_css '.flash_messages', text: 'invalid or expired'
      end
    end

    context 'when asking the ILS to change the PIN fails' do
      before do
        allow(FolioClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:change_pin).and_raise(FolioClient::IlsError)
      end

      it 'shows the user an error' do
        visit change_pin_with_token_path('foo')
        fill_in('pin', with: 'newpin')
        click_button 'Change PIN'
        expect(page).to have_css '.flash_messages', text: 'Something went wrong'
      end
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
