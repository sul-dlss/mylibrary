# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Proxy User', type: :feature do
  before do
    login_as(username: 'PROXY21', patron_key: '521197')
  end

  it 'has a tab to switch between user and group' do
    visit summaries_path

    expect(page).to have_css('.nav-tabs .nav-link', count: 2)
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Proxy FirstProxyLN')

    click_link 'Group'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Group')

    click_link 'Proxy FirstProxyLN'
    expect(page).to have_css('.nav-tabs .nav-link.active', text: 'Proxy FirstProxyLN')
  end

  it 'toggles between proxy user and group checkouts' do
    visit checkouts_path

    expect(page).to have_text('Programming cultures : art and architecture in the age of software')

    click_link 'Group'
    expect(page).to have_text('Making plans : how to engage with landscape, design, and the urban environment')
    expect(page).not_to have_text('Programming cultures : art and architecture in the age of software')
  end

  it 'toggles between proxy user and group requests' do
    visit requests_path

    expect(page).to have_text('The blockchain and the new architecture of trust')

    click_link 'Group'
    expect(page).to have_text('San Filippo di Fragalà')
    expect(page).not_to have_text('The blockchain and the new architecture of trust')
  end

  it 'toggles between proxy user and group fines' do
    visit fines_path

    expect(page).to have_text('Aspects of grammatical architecture')

    click_link 'Group'
    expect(page).not_to have_text('Aspects of grammatical architecture')
  end
end
