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
    expect(page).to have_css('h3', text: 'Checkouts: 13')
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
      expect(page).to have_css('dd.expired-date', text: 'February 1, 2020')
    end
  end

  context 'with mock data' do
    let(:mock_client) do
      instance_double(
        SymphonyClient,
        patron_info: {
          'fields' => fields
        }.with_indifferent_access
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
  end
end
