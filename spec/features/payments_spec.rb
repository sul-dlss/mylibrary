# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payments History', type: :feature do
  let(:user_with_payments) { '521181' }
  let(:user_with_single_payment) { '521182' }
  let(:user_with_no_payments) { '521206' }

  before do
    login_as(username: 'SUPER1', patron_key: user_with_payments)
  end

  context 'with no payments' do
    before do
      login_as(username: 'NOTHING', patron_key: user_with_no_payments)
    end

    it 'does not load table', js: true do
      visit fines_path
      click_on 'Show history'

      expect(page).to have_css('span', text: 'There is no history on this account')
    end
  end

  context 'with a single payment' do
    before do
      login_as(username: 'SUPER2', patron_key: user_with_single_payment)
    end

    it 'renders a list item for a single payment', js: true do
      visit fines_path
      click_on 'Show history'

      within('ul.payments') do
        expect(page).to have_css('li', count: 1)
        expect(page).to have_css('li h3', text: 'No item associated with this payment')
        expect(page).to have_css('li .bill_description', text: 'Privileges fee')
      end
    end

    it 'has content behind a payments toggle', js: true do
      visit fines_path
      click_on 'Show history'

      within('ul.payments') do
        within(first('li')) do
          expect(page).not_to have_css('dl', visible: :visible)
          expect(page).not_to have_css('dt', text: 'Resolution', visible: :visible)
          click_button 'Expand'
          expect(page).to have_css('dl', visible: :visible)
          expect(page).to have_css('dt', text: 'Resolution', visible: :visible)
        end
      end
    end
  end

  context 'with multiple payments' do
    it 'has a header for payment history' do
      visit fines_path

      expect(page).to have_css('h2', text: 'History')
    end

    it 'renders a list item for every payment', js: true do
      visit fines_path
      click_on 'Show history'

      within('ul.payments') do
        expect(page).to have_css('li', count: 2)
        expect(page).to have_css('li h3', text: 'California : a history')
        expect(page).to have_css('li .bill_description', text: 'Overdue item')
      end
    end

    it 'has content behind a payments toggle', js: true do
      visit fines_path
      click_on 'Show history'

      within('ul.payments') do
        within(first('li')) do
          expect(page).not_to have_css('dl', visible: :visible)
          expect(page).not_to have_css('dt', text: 'Resolution', visible: :visible)
          click_button 'Expand'
          expect(page).to have_css('dl', visible: :visible)
          expect(page).to have_css('dt', text: 'Resolution', visible: :visible)
        end
      end
    end

    it 'is sortable', js: true do
      visit fines_path
      click_on 'Show history'

      within '#payments' do
        expect(page).to have_css('.dropdown-toggle', text: 'Sort (Date paid)')
        find('[data-sort="bill_description"]').click

        expect(page).to have_css('.dropdown-toggle', text: 'Sort (Reason)')
        expect(page).to have_css('.active[data-sort="bill_description"]', count: 2, visible: :all)

        within(first('ul.payments li')) do
          expect(page).to have_css('.bill_description', text: /Overdue item/)
        end
      end
    end
  end
end
