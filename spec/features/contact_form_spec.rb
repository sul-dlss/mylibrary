# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contact form', type: :feature do
  context 'with user logged in' do
    let(:patron) do
      Patron.new('fields' => { 'address1' => [], 'standing' => { 'key' => '' }, 'profile' => { 'key' => '' } })
    end

    let(:mock_client) do
      instance_double(
        SymphonyClient,
        checkouts: { 'fields' => { 'circRecordList' => [] } },
        requests: { 'fields' => { 'holdRecordList' => [] } },
        fines: { 'fields' => { 'blockList' => [] } },
        patron_info: patron
      )
    end

    before do
      allow(SymphonyClient).to receive(:new).and_return(mock_client)
      login_as(username: 'stub_user')
      visit root_path
    end

    describe 'hidden', js: true do
      it 'form should be hidden' do
        expect(page).not_to have_css('.contact-form', visible: true)
      end
    end

    describe 'visible', js: true do
      before do
        click_link 'Contact Access Services'
      end

      it 'is shown' do
        expect(page).to have_css('#contact-modal-window', visible: true)
        page.save_screenshot('screen.png')
      end

      it 'has a Cancel link' do
        expect(page).to have_css('.contact-form button', text: 'Cancel')
      end

      it 'has a Send button' do
        expect(page).to have_css('.contact-form button', text: 'Send')
      end

      describe 'filled out and submitted' do
        before do
          within 'form.contact-form' do
            fill_in('message', with: 'This is only a test')
            click_button 'Send'
          end
        end

        it 'displays a success message' do
          expect(page).to have_css('div.alert-success',
                                   text: 'Thank you! Someone from Access Services will be in touch with you soon.')
        end
      end
    end
  end

  context 'with user not logged in' do
    before do
      visit root_path
    end

    describe 'hidden', js: true do
      it 'form should be absent' do
        expect(page).not_to have_css('.contact-form')
      end
    end

    describe 'contact links in the header' do
      it 'does not show the modal form link' do
        expect(page).not_to have_css('.navbar-link', text: 'Contact Access Services')
      end

      it 'does not show the telephone number' do
        expect(page).not_to have_css('.navbar-link', text: '(650) 723-1493')
      end
    end
  end
end
