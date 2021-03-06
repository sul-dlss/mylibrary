# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sponsor User', type: :feature do
  before do
    login_as(username: 'FACULTY2', patron_key: '521187')
  end

  it 'has a tab to switch between user and group' do
    visit summaries_path

    expect(page).to have_css('.nav-tabs .nav-link', count: 2)
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self')

    click_link 'Proxies'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Proxies')

    click_link 'Self'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self')
  end

  it 'shows the pay fine button on the self tab only' do
    visit summaries_path

    expect(page).to have_css('button.btn', text: 'Pay $13.00 now')

    click_link 'Proxies'
    expect(page).to have_text('Fines can be paid in My Library Account only by the borrower who accrued them')
    expect(page).not_to have_css('a.btn', text: 'Pay $340.00 now')
  end
end
