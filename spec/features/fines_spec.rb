# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fines Page' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron_info) do
    build(:patron_with_fines).patron_info
  end

  before do
    allow(FolioClient).to receive(:new) { mock_client }
    allow(mock_client).to receive_messages(patron_info: patron_info)
    login_as(username: 'stub_user', patron_key: '50e8400-e29b-41d4-a716-446655440000')
  end

  context 'with fines' do
    it 'totals all the fines into the header' do
      visit fines_path

      expect(page).to have_css('h2', text: 'Payable: $325.00')
    end

    it 'totals all the accruing fines' do
      visit fines_path

      expect(page).to have_css('h2', text: 'Accruing: $25.00')
      expect(page).to have_content 'Fines are accruing on 1 overdue item'
    end

    it 'renders a list item for every fine' do
      visit fines_path

      within('ul.fines') do
        expect(page).to have_css('li', count: 1)
        expect(page).to have_css('li h3', text: 'Memes and the future of pop culture / by Marcel Danesi')
        expect(page).to have_css('li .status', text: 'Damaged material')
        expect(page).to have_css('li a', text: 'Contact library')
      end
    end

    it 'has content behind a toggle', :js do
      visit fines_path

      within('ul.fines') do
        expect(page).not_to have_css('dl', visible: :visible)
        expect(page).not_to have_css('dt', text: 'Billed', visible: :visible)
        click_button 'Expand'
        expect(page).to have_css('dl', visible: :visible)
        expect(page).to have_css('dt', text: 'Billed', visible: :visible)
        expect(page).to have_css('dt', text: 'Barcode', visible: :visible)
        expect(page).to have_css('dd', text: '36105228879115', visible: :visible)
      end
    end
  end

  context 'with no fines' do
    let(:patron_info) do
      build(:sponsor_patron).patron_info
    end

    it 'does not render table headers' do
      visit fines_path

      expect(page).not_to have_css('.list-header')
    end
  end
end
