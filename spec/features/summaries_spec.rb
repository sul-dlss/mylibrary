# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Summaries Page', type: :feature do
  before do
    login_as(username: 'SUPER1', patron_key: '521181')
  end

  it 'has a logout button' do
    visit summaries_url

    expect(page).to have_link 'SUPER1: logout'
  end
end
