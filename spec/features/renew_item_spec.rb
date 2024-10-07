# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Renew item', :js do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }
  let(:patron_info) do
    build(:sponsor_patron).patron_info
  end

  let(:service_points) do
    build(:service_points)
  end

  let(:api_response) { instance_double(Faraday::Response, status: 201) }
  let(:bulk_renew_response) do
    { success: [instance_double(Folio::Checkout, key: '1', renewable?: true, item_id: '123', title: 'ABC')] }
  end

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_messages(patron_info:,
                                           renew_item_by_id: api_response,
                                           renew_items: bulk_renew_response)
    allow(Folio::ServicePoint).to receive_messages(
      all: service_points
    )
    allow(Folio::LoanPolicy).to receive(:new).and_return(build(:grad_mono_loans,
                                                               due_date: '2021-01-09T07:59:59.000+00:00',
                                                               renewal_count: 0))

    login_as(User.new(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1'))
  end

  it 'enabled through checkout page' do
    visit checkouts_path

    within(first('ul.checkouts li')) do
      click_on 'Expand'
      first('.btn-renewable-submit').click
    end
    expect(page).to have_css '.flash_messages', text: 'Success!'
  end

  it 'has a button to renew all items' do
    skip 'Mocking the response does not seem to work'

    visit checkouts_path

    click_on 'Renew 1 eligible item'

    expect(page).to have_css '.flash_messages', text: 'Success!'
  end
end
