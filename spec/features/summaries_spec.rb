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
    expect(page).to have_css('dd.email', text: 'somebody@stanford.edu')
    expect(page).not_to have_css('dd.patron-type')
  end
end
