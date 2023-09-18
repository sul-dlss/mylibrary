# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request Page' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron_info) do
    build(:sponsor_patron).patron_info
  end

  let(:service_points) do
    build(:service_points)
  end

  let(:api_response) { instance_double('Response', status: 204, content_type: :json) }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_messages(patron_info: patron_info,
                                           cancel_hold_request: api_response,
                                           change_pickup_service_point: api_response,
                                           change_pickup_expiration: api_response)
    allow(Folio::ServicePoint).to receive_messages(
      all: service_points
    )

    login_as(username: 'SUPER2', patron_key: '50e8400-e29b-41d4-a716-446655440000')
  end

  it 'has ready for pickup request data' do
    visit requests_path

    expect(page).to have_css('ul.ready-requests', count: 1)
    expect(page).to have_css('ul.ready-requests li', count: 2)

    within(first('ul.ready-requests li')) do
      expect(page).to have_css('.library', text: 'Green Library')
      expect(page).to have_css('.title', text: /Rothko : the color field paintings/)
      expect(page).to have_css('.call_number', text: 'ND237 .R725 A4 2017 F')
    end
  end

  it 'ready for pickup can be cancelled' do
    visit requests_path

    within(first('ul.ready-requests li')) do
      first('.btn-request-cancel').click
    end
    expect(page).to have_css '.flash_messages', text: 'Success!'
  end

  it 'has requested data' do
    visit requests_path

    expect(page).to have_css('ul.requested-requests', count: 1)
    expect(page).to have_css('ul.requested-requests li', count: 2)

    within(first('ul.requested-requests li')) do
      expect(page).to have_css('.library', text: 'Classics')
      expect(page).to have_css('.title', text: 'A history of Persia')
      expect(page).to have_css('.call_number', text: 'DS298 .W3 2023')
    end
  end

  it 'hides some data behind a toggle', :js do
    visit requests_path

    within(first('ul.ready-requests li')) do
      expect(page).not_to have_css('dl', visible: :visible)
      expect(page).not_to have_css('dt', text: 'Requested:', visible: :visible)
      click_button 'Expand'
      expect(page).to have_css('dl', visible: :visible)
      expect(page).to have_css('dt', text: 'Requested:', visible: :visible)
    end
  end

  it 'is editable' do
    visit edit_request_path('7fa87cfe-df57-4dc7-953b-a5a44ff37d91')
    select('Engineering Library (Terman)', from: 'service_point')
    fill_in('not_needed_after', with: '1999/01/01')
    click_button 'Change'
    expect(page).to have_css 'div.alert-success', text: 'Success!', count: 2
  end

  it 'is sortable', :js do
    visit requests_path

    within '#requests' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Not needed after)')
      find('[data-sort="title"]').click

      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Title)')
      expect(page).to have_css('.active[data-sort="title"]', count: 2, visible: :all)

      within(first('ul.requested-requests li')) do
        expect(page).to have_css('.title', text: /A history of Persia/)
      end
    end
  end

  context 'with no requests' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }.with_indifferent_access
    end

    before do
      login_as(username: 'NOTHING', patron_key: '50e8400-e29b-41d4-a716-446655440000')
    end

    it 'does not render table headers' do
      visit requests_path

      expect(page).not_to have_css('.list-header')
    end
  end
end
