# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Renew item', js: true do
  before do
    login_as(username: 'SUPER1', patron_key: '521181')
  end

  it 'enabled through checkout page' do
    visit checkouts_path

    within(first('ul.checkouts li')) do
      click_button 'Expand'
      first('.btn-renewable-submit').click
    end
    expect(page).to have_css '.flash_messages', text: 'Success!'
  end

  it 'has a button to renew all items' do
    visit checkouts_path

    click_on 'Renew 8 eligible items'

    expect(page).to have_css '.flash_messages', text: 'Success!'
  end
end
