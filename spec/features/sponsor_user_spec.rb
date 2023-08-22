# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sponsor User' do
  before do
    login_as(username: 'FACULTY2', patron_key: '521187')
  end

  it 'has a tab to switch between user and group' do
    visit summaries_path

    expect(page).to have_css('.nav-tabs .nav-link', count: 2)
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self')

    click_link 'Proxy group'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Proxy group')

    click_link 'Self'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self')
  end

  it 'shows the pay fine button on the self tab only' do
    visit summaries_path

    expect(page).to have_button 'Pay $13.00 now'

    click_link 'Proxy group'
    expect(page).to have_text('Fines can be paid in My Library Account only by the borrower who accrued them')
    expect(page).not_to have_link 'Pay $340.00 now'
  end
end
