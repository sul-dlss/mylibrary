# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fines Page', type: :feature do
  let(:user_with_payments) { '521181' }
  let(:user_witout_fines) { '521206' }
  let(:user_with_single_payment) { '521182' }

  before do
    login_as(username: 'SUPER1', patron_key: user_with_payments)
  end

  context 'with fines' do
    it 'totals all the fines into the header' do
      visit fines_path

      expect(page).to have_css('h2', text: 'Payable: $7.00')
    end

    it 'totals all the accruing fines' do
      visit fines_path

      expect(page).to have_css('h2', text: 'Accruing: $72.00')
      expect(page).to have_content 'Fines are accruing on 4 overdue items'
    end

    it 'renders a list item for every fine' do
      visit fines_path

      within('ul.fines') do
        expect(page).to have_css('li', count: 1)
        expect(page).to have_css('li h3', text: 'Research handbook on the law of virtual and augmented reality')
        expect(page).to have_css('li .status', text: 'Damaged item')
        expect(page).to have_css('li a', text: 'Contact library')
      end
    end

    it 'has content behind a toggle', js: true do
      visit fines_path

      within('ul.fines') do
        expect(page).not_to have_css('dl', visible: true)
        expect(page).not_to have_css('dt', text: 'Billed', visible: true)
        click_button 'Expand'
        expect(page).to have_css('dl', visible: true)
        expect(page).to have_css('dt', text: 'Billed', visible: true)
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
          expect(page).not_to have_css('dl', visible: true)
          expect(page).not_to have_css('dt', text: 'Resolution', visible: true)
          click_button 'Expand'
          expect(page).to have_css('dl', visible: true)
          expect(page).to have_css('dt', text: 'Resolution', visible: true)
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
        expect(page).to have_css('.active[data-sort="bill_description"]', count: 2, visible: false)

        within(first('ul.payments li')) do
          expect(page).to have_css('.bill_description', text: /Overdue item/)
        end
      end
    end
  end

  context 'when user has a single payment' do
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
          expect(page).not_to have_css('dl', visible: true)
          expect(page).not_to have_css('dt', text: 'Resolution', visible: true)
          click_button 'Expand'
          expect(page).to have_css('dl', visible: true)
          expect(page).to have_css('dt', text: 'Resolution', visible: true)
        end
      end
    end
  end

  context 'with no fines' do
    before do
      login_as(username: 'NOTHING', patron_key: user_witout_fines)
    end

    it 'does not render table headers' do
      visit fines_path

      expect(page).not_to have_css('.list-header')
    end
  end

  context 'when a user pays a fine' do
    before do
      login_as(username: 'SUPER2', patron_key: user_with_single_payment)
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ActionDispatch::Flash::RequestMethods).to receive(:flash).and_return(payment_pending: true)
      # rubocop:enable RSpec/AnyInstance
    end

    it 'shows pending when flash is set' do
      visit fines_path

      expect(page).to have_css('span', text: 'pending')
    end
  end
end
