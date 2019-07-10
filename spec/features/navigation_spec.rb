# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Navigation', type: :feature do
  let(:mock_client) { instance_double(SymphonyClient, checkouts: { 'fields' => { 'circRecordList' => [] } }) }

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
    login_as 'stub_user'
  end

  it 'the root path navigates to the Summary page' do
    visit root_path

    expect(page).to have_css('h1', text: 'Summary')
  end

  it 'has navigation with links to the main pages' do
    visit root_path

    within('main nav') do
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
end
