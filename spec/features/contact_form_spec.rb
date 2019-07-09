# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contact form', type: :feature do
  before do
    page.driver.browser.manage.window.resize_to(600, 800)
    visit root_path
  end

  describe 'hidden contact form', js: true do
    it 'contact form should be hidden' do
      expect(page).not_to have_css('.contact-form', visible: true)
    end
  end

  describe 'visible contact form', js: true do
    before do
      click_link 'Contact Access Services'
    end

    it 'contact form should be shown' do
      expect(page).to have_css('#contact-modal-window', visible: true)
      click_link 'Cancel'
    end

    it 'contact form should have a Send button and a Cancel link' do
      expect(page).to have_css('.contact-form button', text: 'Send')
      click_link 'Cancel'
    end

    it 'contact form should have a Cancel link' do
      expect(page).to have_css('.contact-form a', text: 'Cancel')
      click_link 'Cancel'
    end

    describe 'filling out and submitting contact form' do
      before do
        within 'form.contact-form' do
          fill_in('message', with: 'This is only a test')
          click_button 'Send'
        end
      end

      it 'contact form should be filled out and submitted' do
        expect(page).to have_css('div.alert-success',
                                 text: 'Thank you! Someone from Access Services will be in touch with you soon.')
      end
    end
  end
end
