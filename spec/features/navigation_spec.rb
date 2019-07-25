# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Navigation', type: :feature do
  let(:mock_client) do
    instance_double(
      SymphonyClient,
      patron_info: {
        'fields' => fields
      }.with_indifferent_access,
      session_token: '1a2b3c4d5e6f8g9h0j'
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

  it 'allows the user to navigate to the checkouts page' do
    visit root_path

    click_link 'Checkouts'

    expect(page).to have_css('h1', text: 'Checkouts')
  end

  it 'allows the user to navigate to the requests page' do
    visit root_path

    click_link 'Requests'

    expect(page).to have_css('h1', text: 'Requests')
  end

  it 'allows the user to navigate to the fines page' do
    visit root_path

    click_link 'Fines'

    expect(page).to have_css('h1', text: 'Fines')
  end

  it 'allows the user to navigate from a page back to the summary page' do
    visit fines_path

    click_link 'Summary'

    expect(page).to have_css('h1', text: 'Summary')
  end

  it 'has an active class for the active page' do
    visit fines_path

    expect(page).to have_css('.nav-link.active', text: 'Fines')
  end

  context 'with a patron in good standing' do
    before do
      fields[:standing] = { key: 'OK' }
      fields[:circRecordList] = [{ fields: {} }, { fields: {} }]
      fields[:holdRecordList] = [{ fields: {} }]
    end

    it 'shows the patron status and various counts' do
      visit summaries_path

      expect(page).to have_css('.nav-link.active', text: 'Summary OK')
      expect(page).to have_css('.nav-link', text: 'Checkouts 2')
      expect(page).to have_css('.nav-link', text: 'Requests 1')
      expect(page).to have_css('.nav-link', text: 'Fines $0.00')
    end
  end

  context 'with a blocked patron' do
    before do
      fields[:standing] = { key: 'BARRED' }
    end

    it 'shows the patron status and various counts' do
      visit summaries_path

      expect(page).to have_css('.nav-link.active', text: 'Summary Blocked')
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

      expect(page).to have_css('.nav-link', text: 'Checkouts 2 recalls')
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

      expect(page).to have_css('.nav-link', text: 'Checkouts 3 overdue')
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

      expect(page).to have_css('.nav-link', text: 'Requests 3 ready')
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

      expect(page).to have_css('.nav-link', text: 'Fines $100.00')
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

      expect(page).to have_css('.nav-link', text: 'Fines $100.00')
    end
  end

  context 'with a group' do
    before do
      # Un-stub the symphony client so we hit our fixture data endpoint
      allow(SymphonyClient).to receive(:new).and_call_original

      login_as(username: 'PROXY21', patron_key: '521197')
    end

    it 'preserves the group parameter across navigation' do
      visit summaries_path

      click_link 'Group'
      expect(page).to have_css('.nav-link.active', text: 'Group')

      click_link 'Requests'
      expect(page).to have_css('.nav-link.active', text: 'Group')

      click_link 'Checkouts'
      expect(page).to have_css('.nav-link.active', text: 'Group')

      click_link 'Fines'
      expect(page).to have_css('.nav-link.active', text: 'Group')

      click_link 'Summary'
      expect(page).to have_css('.nav-link.active', text: 'Group')
    end
  end
end
