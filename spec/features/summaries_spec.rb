# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Summaries Page' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }

  let(:patron_info) do
    build(:undergraduate_patron).patron_info
  end

  let(:sponsor) do
    {}
  end

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new) { mock_client }
    allow(Folio::LoanPolicy).to receive(:new).and_return(build(:grad_mono_loans))
    allow(mock_client).to receive_messages(patron_info:)
    allow(mock_client).to receive(:patron_info).with('ec52d62d-9f0e-4ea5-856f-a1accb0121d1').and_return(sponsor)
    login_as(username: 'stub_user', patron_key: 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f')

    visit summaries_path
  end

  it 'has a logout button' do
    expect(page).to have_link 'stub_user: logout'
  end

  it 'has patron data' do
    expect(page).to have_css('h2', text: 'Ursula Undergrad')
    expect(page).to have_css('dd.patron-status', text: 'Blocked')
    expect(page).to have_css('dd.email', text: 'superuser1@stanford.edu')
    expect(page).to have_no_css('dd.expired-date')
    expect(page).to have_no_css('dd.patron-type')
  end

  it 'has summary data' do
    expect(page).to have_css('h3', text: 'Checkouts: 1')
    expect(page).to have_css('h3', text: 'Requests: 3')
    expect(page).to have_css('h3', text: 'Fines & fees payable: $200.00')
    expect(page).to have_css('div', text: '$200.00 accruing on overdue items')
  end

  context 'with overdue items' do
    let(:patron_info) do
      build(:patron_with_overdue_items).patron_info
    end

    it 'has summary data' do
      expect(page).to have_css('div', text: '1 overdue')
    end
  end

  context 'with requests ready for pickup' do
    let(:patron_info) do
      build(:sponsor_patron).patron_info
    end

    it 'has summary data' do
      expect(page).to have_css('div', text: '2 ready for pickup')
    end
  end

  context 'with recalled items' do
    let(:patron_info) do
      build(:patron_with_recalls).patron_info
    end

    it 'has summary data' do
      expect(page).to have_css('div', text: '1 recalled')
    end
  end

  context 'with a proxy borrower' do
    let(:patron_info) do
      build(:proxy_patron).patron_info
    end

    let(:sponsor) do
      build(:sponsor_patron).patron_info
    end

    it 'has patron data' do
      expect(page).to have_css('h2', text: 'Piper Proxy')
      expect(page).to have_css('dd.patron-status', text: 'OK')
      expect(page).to have_css('dd.email', text: 'proxy_patron@stanford.edu')
    end
  end

  context 'with an inactive patron' do
    subject(:patron_info) do
      {
        'user' => { 'active' => false, 'expirationDate' => '2023-06-16T19:00:24.000+00:00', 'manualBlocks' => [],
                    'blocks' => [] }, 'loans' => [], 'holds' => [], 'accounts' => []
      }
    end

    it 'has patron data' do
      expect(page).to have_css('dd.patron-status', text: 'Expired')
      expect(page).to have_css('dd.expired-date', text: 'June 16, 2023')
    end
  end

  context 'with no data returned' do
    let(:mock_client) { instance_double(FolioClient, ping: false) }

    it 'redircts to the system unavailable page' do
      expect(page).to have_css('div', text: 'Temporarily unavailable')
    end
  end
end
