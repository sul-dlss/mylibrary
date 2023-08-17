# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Checkout Page' do
  before do
    login_as(username: 'SUPER1', patron_key: '521181')
  end

  it 'has checkout data' do
    visit checkouts_path

    expect(page).to have_css('ul.checkouts', count: 1)
    expect(page).to have_css('ul.checkouts li', count: 12)

    within(first('ul.checkouts li')) do
      expect(page).to have_css('.status', text: 'Overdue')
      expect(page).to have_css('.title', text: /On video games/)
      expect(page).to have_css('.call_number', text: 'GV1469.34 .S52 M874 2018')
    end

    within('ul.checkouts li:nth-child(5)') do
      expect(page).to have_css('.status', text: 'Overdue $30.00')
    end
  end

  it 'has recall data' do
    visit checkouts_path

    expect(page).to have_css('ul.recalled-checkouts', count: 1)
    expect(page).to have_css('ul.recalled-checkouts li', count: 1)

    within(first('ul.recalled-checkouts li')) do
      expect(page).to have_css('.status', text: 'Recalled')
      expect(page).to have_css('.title', text: /Pikachu's global adventure/)
      expect(page).to have_css('.call_number', text: 'GV1469.35 .P63 P54 2004')
    end
  end

  it 'has renewable status indicator' do
    visit checkouts_path

    expect(page).to have_css '.renewable-indicator .sul-icons'
  end

  context 'when data is hidden behind a toggle' do
    it 'shows the renew data when the list item is expanded', js: true do
      visit checkouts_path

      within('ul.checkouts li:nth-child(4)') do
        click_button 'Expand'
        expect(page).to have_css('dt', text: 'Can I renew?', visible: :visible)
      end
    end

    it 'shows other data when the list item is expanded', js: true do
      visit checkouts_path

      within(first('ul.checkouts li')) do
        expect(page).not_to have_css('dl', visible: :visible)
        expect(page).not_to have_css('dt', text: 'Borrowed:', visible: :visible)
        click_button 'Expand'
        expect(page).to have_css('dl', visible: :visible)
        expect(page).to have_css('dt', text: 'Borrowed:', visible: :visible)
        expect(page).to have_css('dt', text: 'Days overdue:', visible: :visible)
        expect(page).to have_css('dd', text: /^\d+$/, visible: :visible)
        expect(page).to have_css('dt', text: 'Barcode:', visible: :visible)
        expect(page).to have_css('dd', text: '36105229207159', visible: :visible)
      end

      within('ul.checkouts li:nth-child(5)') do
        click_button 'Expand'
        expect(page).to have_css('dt', text: 'Fines accrued:', visible: :visible)
        expect(page).to have_css('dd', text: '$30.00', visible: :visible)
      end
    end
  end

  it 'translates the library code from the response into a name' do
    visit checkouts_path

    within(first('ul.checkouts li')) do
      expect(page).to have_css('dl dd', text: 'Green Library', visible: :all)
    end
  end

  it 'is sortable', js: true do
    visit checkouts_path

    within '#checkouts' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Due date)')
      find('[data-sort="title"]').click

      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Title)')
      expect(page).to have_css('.active[data-sort="title"]', count: 2, visible: :all)

      within(first('ul.checkouts li')) do
        expect(page).to have_css('.title', text: /Japanese animation/)
      end
    end
  end

  context 'with a user who has no checkouts' do
    before do
      login_as(username: 'NOTHING', patron_key: '521206')
    end

    it 'does not render table headers' do
      expect(page).not_to have_css('.list-header')
    end
  end
end
