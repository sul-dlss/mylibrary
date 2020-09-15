# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request Page', type: :feature do
  before do
    login_as(username: 'SUPER2', patron_key: '521182')
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
    expect(page).to have_css('ul.requested-requests li', count: 3)

    within(first('ul.requested-requests li')) do
      expect(page).to have_css('.library', text: 'Art & Architecture Library')
      expect(page).to have_css('.title', text: 'Colour and light in ancient and medieval art')
      expect(page).to have_css('.call_number', text: 'N5315 .C65 2018')
    end
  end

  it 'hides some data behind a toggle', js: true do
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
    visit edit_request_path('1675117')
    select('East Asia Library', from: 'pickup_library')
    fill_in('not_needed_after', with: '1999/01/01')
    click_button 'Change'
    expect(page).to have_css 'div.alert-success', text: 'Success!', count: 2
  end

  it 'is sortable', js: true do
    visit requests_path

    within '#requests' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Not needed after)')
      find('[data-sort="title"]').click

      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Title)')
      expect(page).to have_css('.active[data-sort="title"]', count: 2, visible: :all)

      within(first('ul.requested-requests li')) do
        expect(page).to have_css('.title', text: /Colour and light/)
      end
    end
  end

  context 'with no requests' do
    before do
      login_as(username: 'NOTHING', patron_key: '521206')
    end

    it 'does not render table headers' do
      visit requests_path

      expect(page).not_to have_css('.list-header')
    end
  end

  context 'with a mock user' do
    let(:mock_client) do
      instance_double(
        SymphonyClient,
        patron_info: {
          'fields' => fields
        }.with_indifferent_access,
        ping: true
      )
    end

    let(:fields) do
      {
        address1: [],
        standing: { key: '' },
        profile: { key: '' },
        circRecordList: [],
        blockList: [],
        holdRecordList: []
      }
    end

    before do
      allow(SymphonyClient).to receive(:new) { mock_client }
      login_as(username: 'stub_user')
    end

    context 'with an eligible patron with a pickup at Green' do
      before do
        fields[:profile]['key'] = 'MXF'
        fields[:firstName] = 'My'
        fields[:lastName] = 'Name'
        fields[:holdRecordList] = [
          { key: '1', fields: { status: 'BEING_HELD', pickupLibrary: { key: 'GREEN' } } }
        ]
      end

      it 'renders a button to schedule access to Green' do
        visit requests_path
        click_link 'Schedule pickup at Green Library'
        expect(page).to have_css '.modal-body iframe'
        src = find('iframe')[:src]
        expect(src).to start_with 'https://go.oncehub.com/StanfordLibrariesPagingPickupGreenLibrary'
        expect(src).to include 'name=My%20Name'
      end
    end

    context 'with an eligible patron without a pickup at Green' do
      before do
        fields[:profile]['key'] = 'MXF'
        fields[:firstName] = 'My'
        fields[:lastName] = 'Name'
        fields[:holdRecordList] = []
      end

      it 'renders a button to schedule access to Green' do
        visit requests_path
        expect(page).not_to have_link 'Schedule pickup at Green Library'
      end
    end

    context 'with an ineligible patron with a pickup at Green' do
      before do
        fields[:profile]['key'] = 'MXFEE'
        fields[:firstName] = 'My'
        fields[:lastName] = 'Name'
        fields[:holdRecordList] = [
          { key: '1', fields: { status: 'BEING_HELD', pickupLibrary: { key: 'GREEN' } } }
        ]
      end

      it 'renders a button to schedule access to Green' do
        visit requests_path
        expect(page).not_to have_link 'Schedule pickup at Green Library'
      end
    end

    context 'with an eligible patron with an item at spec' do
      before do
        fields[:profile]['key'] = 'MXF'
        fields[:firstName] = 'My'
        fields[:lastName] = 'Name'
        fields[:holdRecordList] = [
          { key: '1', fields: { status: 'BEING_HELD', pickupLibrary: { key: 'SPEC-DESK' } } }
        ]
      end

      it 'renders a button to schedule access to Green' do
        visit requests_path
        click_link 'Schedule visit to Special Collections'
        expect(page).to have_css '.modal-body iframe'
        src = find('iframe')[:src]
        expect(src).to start_with 'https://go.oncehub.com/StanfordLibrariesVisitSpecialCollections'
        expect(src).to include 'name=My%20Name'
      end
    end

    context 'with an eligible patron without an item at spec' do
      before do
        fields[:profile]['key'] = 'MXF'
        fields[:firstName] = 'My'
        fields[:lastName] = 'Name'
        fields[:holdRecordList] = []
      end

      it 'renders a button to schedule access to Green' do
        visit requests_path
        expect(page).not_to have_link 'Schedule visit to Special Collections'
      end
    end

    context 'with an ineligible patron with an item at spec' do
      before do
        fields[:profile]['key'] = 'MXFEE'
        fields[:firstName] = 'My'
        fields[:lastName] = 'Name'
        fields[:holdRecordList] = [
          { key: '1', fields: { status: 'BEING_HELD', pickupLibrary: { key: 'SPEC-COLL' } } }
        ]
      end

      it 'renders a button to schedule access to Green' do
        visit requests_path
        expect(page).not_to have_link 'Schedule visit to Special Collections'
      end
    end
  end
end
