# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fines Page', type: :feature do
  before do
    login_as(username: 'SUPER1', patron_key: '521181')
  end

  it 'totals all the fines into the header' do
    visit fines_path

    expect(page).to have_css('h2', text: 'Payable: $7.00')
  end

  it 'totals all the accruing fines' do
    visit fines_path

    expect(page).to have_css('h2', text: 'Accruing: $33.00')
    expect(page).to have_content 'Fines are accruing on 2 overdue items'
  end

  it 'renders a list item for every fine' do
    visit fines_path

    within('ul.fines') do
      expect(page).to have_css('li', count: 1)
      expect(page).to have_css('li h3', text: 'Research handbook on the law of virtual and augmented reality')
      expect(page).to have_css('li .status', text: 'Damaged item')
    end
  end

  it 'has content behind a toggle', js: true do
    visit fines_path

    within('ul.fines') do
      expect(page).not_to have_css('dl', visible: true)
      expect(page).not_to have_css('dt', text: 'Billed on', visible: true)
      click_button 'Expand'
      expect(page).to have_css('dl', visible: true)
      expect(page).to have_css('dt', text: 'Billed on', visible: true)
    end
  end
end
