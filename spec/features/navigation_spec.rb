# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Navigation' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }

  let(:patron_info) do
    {
      'user' => { 'active' => active, 'manualBlocks' => manual_blocks, 'blocks' => blocks },
      'loans' => [],
      'holds' => [],
      'accounts' => []
    }
  end
  let(:active) { true }
  let(:manual_blocks) { [] }
  let(:blocks) { [] }

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new) { mock_client }
    allow(mock_client).to receive_messages(patron_info:)
    allow(Folio::LoanPolicy).to receive(:new).and_return(build(:grad_mono_loans))
    login_as(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')
  end

  it 'the root path navigates to the Summary page' do
    visit root_path

    expect(page).to have_css('h1', text: 'Summary')
  end

  it 'has navigation with links to the main pages' do
    visit root_path

    within('#mainnav') do
      expect(page).to have_link('Summary')
      expect(page).to have_link('Checkouts')
      expect(page).to have_link('Requests')
      expect(page).to have_link('Fines')
    end
  end

  it 'has aria-current labels' do
    visit checkouts_path

    expect(page).to have_css '[aria-current="page"][href^="/checkouts"]'
    expect(page).to have_css '[aria-current="false"][href^="/requests"]'
  end

  it 'allows the user to navigate to the checkouts page' do
    visit root_path

    click_on 'Checkouts'

    expect(page).to have_css('h1', text: 'Checkouts')
  end

  it 'allows the user to navigate to the requests page' do
    visit root_path

    click_on 'Requests'

    expect(page).to have_css('h1', text: 'Requests')
  end

  it 'allows the user to navigate to the fines page' do
    visit root_path

    click_on 'Fines'

    expect(page).to have_css('h1', text: 'Fines')
  end

  it 'allows the user to navigate from a page back to the summary page' do
    visit fines_path

    click_on 'Summary'

    expect(page).to have_css('h1', text: 'Summary')
  end

  it 'has an active class for the active page' do
    visit fines_path

    expect(page).to have_css('.nav-link.active', text: 'Fines')
  end

  context 'with a patron in good standing' do
    it 'shows the patron status and various counts' do
      visit summaries_path

      expect(page).to have_css('.nav-link.active', text: 'Summary OK')
      expect(page).to have_css('.nav-link', text: 'Checkouts 0')
      expect(page).to have_css('.nav-link', text: 'Requests 0')
      expect(page).to have_css('.nav-link', text: 'Fines $0.00')
    end
  end

  context 'with a barred patron' do
    let(:manual_blocks) { ['you are barred'] }

    it 'shows the patron status' do
      visit summaries_path

      expect(page).to have_css('.nav-link.active', text: 'Summary Contact us')
    end
  end

  context 'with a blocked patron' do
    let(:blocks) { ['you are blocked'] }

    it 'shows the patron status' do
      visit summaries_path

      expect(page).to have_css('.nav-link.active', text: 'Summary Blocked')
    end
  end

  context 'with an inactive patron' do
    let(:active) { false }

    it 'shows the patron status' do
      visit summaries_path

      expect(page).to have_css('.nav-link.active', text: 'Summary Expired')
    end
  end

  context 'with a recall' do
    let(:patron_info) do
      build(:patron_with_recalls).patron_info
    end

    it 'shows number of recalled items' do
      visit summaries_path

      expect(page).to have_css('.nav-link', text: 'Checkouts 1 recall')
    end
  end

  context 'with overdue books' do
    let(:patron_info) do
      build(:patron_with_overdue_items).patron_info
    end

    it 'shows number of overdue items' do
      visit summaries_path

      expect(page).to have_css('.nav-link', text: 'Checkouts 1 overdue')
    end
  end

  context 'with requests that are ready for pickup' do
    let(:patron_info) do
      build(:sponsor_patron).patron_info
    end

    it 'shows number of requests ready for pickup' do
      visit summaries_path

      expect(page).to have_css('.nav-link', text: 'Requests 2 ready')
    end
  end

  context 'with fines' do
    let(:patron_info) do
      build(:patron_with_fines).patron_info
    end

    it 'shows the total fines' do
      visit summaries_path

      expect(page).to have_css('.nav-link', text: 'Fines $325.00')
    end
  end

  context 'with a group' do
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
      allow(mock_client).to receive(:patron_info).with('ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(sponsor)
      allow(Folio::ServicePoint).to receive_messages(all: service_points)
    end

    it 'preserves the group parameter across navigation' do
      visit summaries_path

      click_on 'Proxy group'
      expect(page).to have_css('.nav-link.active', text: 'Proxy group')

      click_on 'Requests'
      expect(page).to have_css('.nav-link.active', text: 'Proxy group')

      click_on 'Checkouts'
      expect(page).to have_css('.nav-link.active', text: 'Proxy group')

      click_on 'Fines'
      expect(page).to have_css('.nav-link.active', text: 'Proxy group')

      click_on 'Summary'
      expect(page).to have_css('.nav-link.active', text: 'Proxy group')
    end

    it 'has aria-current and nav labels' do
      visit checkouts_path

      expect(page).to have_css 'nav[aria-label="Proxy tabs"]'
      expect(page).to have_css '[aria-current=true][href^="/checkouts"]'
    end
  end
end
