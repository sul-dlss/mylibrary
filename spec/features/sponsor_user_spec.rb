# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Sponsor User' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true) }

  let(:patron_info) do
    build(:sponsor_patron, custom_properties: { 'loans' => [] }).patron_info
  end

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new) { mock_client }
    allow(mock_client).to receive_messages(patron_info:)
    login_as(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1')

    visit summaries_path
  end

  it 'has a tab to switch between user and group' do
    expect(page).to have_css('.nav-tabs .nav-link', count: 2)
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self')

    click_link 'Proxy group'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Proxy group')

    click_link 'Self'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self')
  end

  it 'shows the pay fine button on the self tab only' do
    expect(page).to have_button 'Pay $150.00 now'

    click_link 'Proxy group'
    expect(page).to have_text('Fines incurred by proxy borrowers appear in the list of ' \
                              "fines under their sponsor's Self tab.")
    expect(page).not_to have_link 'Pay $150.00 now'
  end
end
