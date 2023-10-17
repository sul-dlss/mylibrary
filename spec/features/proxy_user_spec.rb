# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Proxy User' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }

  let(:service_points) do
    build(:service_points)
  end

  let(:patron_info) do
    build(:proxy_patron).patron_info
  end

  let(:sponsor) do
    build(:sponsor_patron).patron_info
  end

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new) { mock_client }
    allow(mock_client).to receive_messages(patron_info:)
    allow(mock_client).to receive(:patron_info).with('ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(sponsor)
    allow(Folio::ServicePoint).to receive_messages(all: service_points)
    allow(Folio::LoanPolicy).to receive(:new).and_return(build(:grad_mono_loans))
    login_as(username: 'stub_user', patron_key: 'bdfa62a1-758c-4389-ae81-8ddb37860f9b')
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

  it 'toggles between proxy user and group checkouts' do
    visit checkouts_path

    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self (1)')
    expect(page).to have_css('.nav-tabs .nav-link', text: 'Proxy group (2)')
    expect(page).to have_text('Sci-fi architecture.')

    click_link 'Proxy group'
    expect(page).to have_text('Music, sound, language, theater')
    expect(page).not_to have_text('Sci-fi architecture.')
    expect(page).to have_text('Piper Proxy')
  end

  it 'toggles between proxy user and group requests' do
    visit requests_path

    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self (1)')
    expect(page).to have_css('.nav-tabs .nav-link', text: 'Proxy group (1)')
    expect(page).to have_text('A history of Persia')
    expect(page).not_to have_text('Borrower:')

    click_link 'Proxy group'
    expect(page).to have_text('Fiction!')
    expect(page).not_to have_text('A history of Persia')
    expect(page).to have_text('Piper Proxy')
  end

  it 'toggles between proxy user and group fines' do
    visit fines_path

    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Self ($200.00)')
    expect(page).to have_css('.nav-tabs .nav-link', text: 'Proxy group ($0.00)')
    expect(page).to have_text('(RE)DISCOVERING THE OLMEC - NATIONAL GEOGRAPHIC SOCIETY-SMITHSONIAN INSTITUTION')

    click_link 'Proxy group'
    expect(page).not_to have_css('.fines')
    expect(page).not_to have_text('(RE)DISCOVERING THE OLMEC - NATIONAL GEOGRAPHIC SOCIETY-SMITHSONIAN INSTITUTION')
  end
end
