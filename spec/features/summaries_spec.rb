# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Summaries Page', type: :feature do
  before do
    login_as(username: 'SUPER1', patron_key: '521181')
    visit summaries_url
  end

  it 'has a logout button' do
    expect(page).to have_link 'SUPER1: logout'
  end

  it 'has patron data' do
    expect(page).to have_css('h2', text: 'Undergrad Superuser')
    expect(page).to have_css('dd.patron-status', text: 'OK')
    expect(page).to have_css('dd.email', text: 'superuser1@stanford.edu')
    expect(page).not_to have_css('dd.expired-date')
    expect(page).not_to have_css('dd.patron-type')
  end

  it 'has summary data' do
    expect(page).to have_css('h3', text: 'Checkouts: 14')
    expect(page).to have_css('div', text: '1 recalled')
    expect(page).to have_css('div', text: '5 overdue')
    expect(page).to have_css('h3', text: 'Requests: 3')
    expect(page).to have_css('div', text: '2 ready for pickup')
    expect(page).to have_css('h3', text: 'Fines & fees payable: $7.00')
    expect(page).to have_css('div', text: '$72.00 accruing on overdue items')
  end

  context 'with a proxy borrower' do
    before do
      login_as(username: 'PROXY21', patron_key: '521197')
      visit summaries_url
    end

    it 'has patron data' do
      expect(page).to have_css('h2', text: 'Second (P=FirstProxyLN) Faculty Group')
      expect(page).to have_css('dd.patron-status', text: 'Blocked')
      expect(page).to have_css('dd.email', text: 'faculty2@stanford.edu')
      expect(page).to have_css('dd.expired-date', text: 'February 1, 2999')
    end
  end

  context 'with mock data' do
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

    context 'with a patron in good standing' do
      before do
        fields[:standing] = { key: 'OK' }
        fields[:circRecordList] = [{ fields: {} }, { fields: {} }]
        fields[:holdRecordList] = [{ fields: {} }]
      end

      it 'shows the patron status and various counts' do
        visit summaries_path

        expect(page).to have_css('h3', text: 'Checkouts: 2')
        expect(page).to have_css('h3', text: 'Requests: 1')
        expect(page).to have_css('h3', text: 'Fines & fees payable: $0.00')
      end
    end

    context 'with a recall' do
      before do
        fields[:circRecordList] = [
          { fields: { recalledDate: '2019-01-01' } },
          { fields: { recalledDate: '2018-02-02' } },
          { fields: { overdue: true } }
        ]
      end

      it 'shows number of recalled items' do
        visit summaries_path

        expect(page).to have_css('div', text: '2 recalled')
      end
    end

    context 'with overdue books' do
      before do
        fields[:circRecordList] = [
          { fields: { overdue: true } },
          { fields: { overdue: true } },
          { fields: { overdue: true } }
        ]
      end

      it 'shows number of overdue items' do
        visit summaries_path

        expect(page).to have_css('div', text: '3 overdue')
      end
    end

    context 'with requests that are ready for pickup' do
      before do
        fields[:holdRecordList] = [
          { fields: { status: 'BEING_HELD' } },
          { fields: { status: 'BEING_HELD' } },
          { fields: { status: 'BEING_HELD' } }
        ]
      end

      it 'shows number of overdue items' do
        visit summaries_path

        expect(page).to have_css('div', text: '3 ready')
      end
    end

    context 'with fines' do
      before do
        fields[:blockList] = [
          { fields: { owed: { amount: 50 } } },
          { fields: { owed: { amount: 30 } } },
          { fields: { owed: { amount: 20 } } }
        ]
      end

      it 'shows the total fines' do
        visit summaries_path

        expect(page).to have_css('h3', text: 'Fines & fees payable: $100.00')
      end
    end

    context 'with accruing overdue fines' do
      before do
        fields[:circRecordList] = [
          { fields: { estimatedOverdueAmount: { amount: 50 } } },
          { fields: { estimatedOverdueAmount: { amount: 30 } } },
          { fields: { estimatedOverdueAmount: { amount: 20 } } }
        ]
      end

      it 'shows number of overdue items' do
        visit summaries_path

        expect(page).to have_css('div', text: '$100.00 accruing on overdue items')
      end
    end

    describe 'ScheduleOnce Buttons' do
      context 'with a user who cannot schedule a visit to Green' do
        before do
          fields[:profile]['key'] = 'CNS'
        end

        it 'renders a button to schedule access to Green' do
          visit summaries_path

          expect(page).not_to have_link 'Schedule access to Green Library'
        end
      end

      context 'with a user who can schedule a visit to Green' do
        before do
          fields[:profile]['key'] = 'MXF'
          fields[:firstName] = 'My'
          fields[:lastName] = 'Name'
        end

        it 'renders a button to schedule access to Green' do
          visit summaries_path

          within '.schedule-dropdown.schedule-visit' do
            click_link 'Green Library'
          end

          expect(page).to have_css '.modal-body iframe'
          src = find('iframe')[:src]
          expect(src).to start_with 'https://go.oncehub.com/StanfordLibrariesGreenEntry'
          expect(src).to include 'name=My%20Name'
        end
      end

      context 'with an eligible patron with a pickup at Green' do
        before do
          fields[:profile]['key'] = 'MXF'
          fields[:firstName] = 'My'
          fields[:lastName] = 'Name'
          fields[:holdRecordList] = [
            { fields: { status: 'BEING_HELD', pickupLibrary: { key: 'GREEN' } } }
          ]
        end

        it 'renders a link to the requests page to schedule access' do
          visit summaries_path

          expect(page).to have_link 'Pick up requests at Green Library'
        end
      end

      context 'with an eligible patron without a pickup' do
        before do
          fields[:profile]['key'] = 'MXF'
          fields[:firstName] = 'My'
          fields[:lastName] = 'Name'
          fields[:holdRecordList] = []
        end

        it 'renders a disabled schedule access links' do
          visit summaries_path
          expect(page).to have_css('a.disabled', text: 'Visit Reading Room')
        end
      end

      context 'with an ineligible patron with a pickup at Green' do
        before do
          fields[:profile]['key'] = 'MXFEE'
          fields[:firstName] = 'My'
          fields[:lastName] = 'Name'
          fields[:holdRecordList] = [
            { fields: { status: 'BEING_HELD', pickupLibrary: { key: 'GREEN' } } }
          ]
        end

        it 'does not render a link to the requests page to schedule access' do
          visit summaries_path
          expect(page).not_to have_link 'Pick up requests at Green Library'
        end
      end

      context 'with an eligible patron with an item at spec' do
        before do
          fields[:profile]['key'] = 'MXF'
          fields[:firstName] = 'My'
          fields[:lastName] = 'Name'
          fields[:holdRecordList] = [
            { fields: { status: 'BEING_HELD', pickupLibrary: { key: 'SPEC-DESK' } } }
          ]
        end

        it 'renders a link to the requests page to schedule access' do
          visit summaries_path
          expect(page).to have_link 'Visit Reading Room'
        end
      end

      context 'with an ineligible patron with an item at spec' do
        before do
          fields[:profile]['key'] = 'MXFEE'
          fields[:firstName] = 'My'
          fields[:lastName] = 'Name'
          fields[:holdRecordList] = [
            { fields: { status: 'BEING_HELD', pickupLibrary: { key: 'SPEC-COLL' } } }
          ]
        end

        it 'does not render a link to the requests page to schedule access' do
          visit summaries_path
          expect(page).not_to have_link 'Visit Reading Room'
        end
      end
    end
  end

  context 'with no data returned' do
    let(:mock_client) do
      instance_double(
        SymphonyClient,
        ping: false
      )
    end

    before do
      allow(SymphonyClient).to receive(:new) { mock_client }
      login_as(username: 'stub_user')
    end

    it 'redircts to the system unavailable page' do
      visit summaries_path

      expect(page).to have_css('div', text: 'Temporarily unavailable')
    end
  end
end
