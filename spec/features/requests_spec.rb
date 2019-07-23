# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request Page', type: :feature do
  before do
    login_as(username: 'SUPER2', patron_key: '521182')
  end

  it 'has ready for pickup request data' do
    visit requests_path

    expect(page).to have_css('ul.ready-requests', count: 1)
    expect(page).to have_css('ul.ready-requests li', count: 2)

    within(first('ul.ready-requests li')) do
      expect(page).to have_css('.library', text: 'Green Library')
      expect(page).to have_css('.title', text: /Rothko : the color field paintings/)
      expect(page).to have_css('.call_number', text: 'ND237 .R725 A4 2017 F')
    end
  end

  it 'ready for pickup can be cancelled' do
    visit requests_path

    within(first('ul.ready-requests li')) do
      first('.btn-request-cancel').click
    end
    expect(page).to have_css '.flash_messages', text: 'Success!'
  end

  it 'has requested data' do
    visit requests_path

    expect(page).to have_css('ul.requested-requests', count: 1)
    expect(page).to have_css('ul.requested-requests li', count: 3)

    within(first('ul.requested-requests li')) do
      expect(page).to have_css('.library', text: 'Green Library')
      expect(page).to have_css('.title', text: /Pikachu's global adventure/)
      expect(page).to have_css('.call_number', text: 'GV1469.35 .P63 P54 2004')
    end
  end

  it 'hides some data behind a toggle', js: true do
    visit requests_path

    within(first('ul.ready-requests li')) do
      expect(page).not_to have_css('dl', visible: true)
      expect(page).not_to have_css('dt', text: 'Requested:', visible: true)
      click_button 'Expand'
      expect(page).to have_css('dl', visible: true)
      expect(page).to have_css('dt', text: 'Requested:', visible: true)
    end
  end

  it 'is sortable', js: true do
    visit requests_path

    within '#requests' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Not needed after)')
      find('[data-sort="title"]').click

      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Title)')
      expect(page).to have_css('.active[data-sort="title"]', count: 2, visible: false)

      within(first('ul.requested-requests li')) do
        expect(page).to have_css('.title', text: /Colour and light/)
      end
    end
  end
end
