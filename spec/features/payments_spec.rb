# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payments History' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  let(:patron_info) do
    build(:undergraduate_patron).patron_info
  end

  before do
    allow(FolioClient).to receive(:new) { mock_client }
    allow(mock_client).to receive_messages(patron_info: patron_info)
    login_as(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')

    visit fines_path
  end

  context 'with payments' do
    it 'has a header for payment history' do
      expect(page).to have_css('h2', text: 'History')
    end

    it 'renders a list item for every payment', :js do
      click_link 'Show history'

      within('ul.payments') do
        expect(page).to have_css('li', count: 10)
        expect(page).to have_css('li h3',
                                 text: 'Aspects of twentieth century art : Picasso - Important paintings, ' \
                                       'watercolours, and new linocuts.')
        expect(page).to have_css('li .bill_description', text: 'Lost item fee')
      end
    end

    it 'has content behind a payments toggle', :js do
      click_link 'Show history'

      within('ul.payments') do
        within(first('li')) do
          expect(page).not_to have_css('dl', visible: :visible)
          expect(page).not_to have_css('dt', text: 'Resolution', visible: :visible)
          click_button 'Expand'
          expect(page).to have_css('dl', visible: :visible)
          expect(page).to have_css('dt', text: 'Resolution', visible: :visible)
        end
      end
    end

    it 'is sortable', :js do
      click_link 'Show history'

      within '#payments' do
        expect(page).to have_css('.dropdown-toggle', text: 'Sort (Date paid)')
        find('[data-sort="bill_description"]').click

        expect(page).to have_css('.dropdown-toggle', text: 'Sort (Reason)')
        expect(page).to have_css('.active[data-sort="bill_description"]', count: 2, visible: :all)

        within(first('ul.payments li')) do
          expect(page).to have_css('.bill_description', text: 'Damaged material')
        end
      end
    end
  end

  context 'with no payments' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end

    it 'does not load table', :js do
      click_link 'Show history'

      expect(page).to have_css('span', text: 'There is no history on this account')
    end
  end
end
