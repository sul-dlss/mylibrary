# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Sponsor User' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true) }

  let(:patron_info) do
    build(:sponsor_patron).patron_info
  end

  before do
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new) { mock_client }
    allow(mock_client).to receive_messages(patron_info: patron_info)
    login_as(username: 'Sponsor1', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1')

    visit summaries_path
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
    skip 'not sure how to get the right data here.'

    expect(page).to have_button 'Pay $325.00 now'

    click_link 'Proxy group'
    expect(page).to have_text('Fines can be paid in My Library Account only by the borrower who accrued them')
    expect(page).not_to have_link 'Pay $340.00 now'
  end
end
