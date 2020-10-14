# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SummariesHelper do
  describe '#scheduler_data_param' do
    it '"encodes" all values and returns the hash as a URL query' do
      expect(
        scheduler_data_param({ blah: 'Jane Stanford', other_blah: 'Hello@example.com' })
      ).to eq 'blah=Jane%20Stanford&other_blah=Hello%40example.com'
    end
  end

  describe '#link_to_schedule_once_visit' do
    before do
      helper.define_singleton_method(:patron_or_group, -> {}) # Define the helper we want to stub
      allow(helper).to receive(:patron_or_group).and_return(
        Patron.new('fields' => { 'profile' => { 'key' => 'MXF' } })
      )
    end

    it 'is a link with the appropriate data attributes' do
      link = helper.link_to_schedule_once_visit(library: 'GREEN', text: 'Green Library')
      expect(link).to include 'data-mylibrary-modal="trigger"'
    end

    it 'links to the appropriate href given the library' do
      link = helper.link_to_schedule_once_visit(library: 'EAST-ASIA', text: 'East Asia Library')
      expect(link).to include 'href="/schedule/eal"'
    end

    it 'uses the given text as the link text' do
      link = Capybara.string(helper.link_to_schedule_once_visit(library: 'GREEN', text: 'Green Library'))
      expect(link).to have_link('Green Library', href: '/schedule/green')
    end
  end

  describe '#schedule_once_link_or_dropdown' do
    before do
      helper.define_singleton_method(:patron_or_group, -> {}) # Define the helper we want to stub
      allow(helper).to receive(:patron_or_group).and_return(patron)
    end

    context 'when the patron has no library access' do
      let(:patron) { Patron.new({ 'fields' => {} }) }

      it 'returns nil if the user is not eligible' do
        expect(helper.schedule_once_link_or_dropdown).to be_nil
      end
    end

    context 'when the user has access to one library' do
      let(:patron) { Patron.new('fields' => { 'profile' => { 'key' => 'MXF' } }) }

      before do
        allow(Settings).to receive(:schedule_access).and_return({ 'GREEN' => true })
      end

      it 'renders a single button to schedule a visit' do
        expect(
          Capybara.string(helper.schedule_once_link_or_dropdown)
        ).to have_link('Enter Green Library for research', href: '/schedule/green')
      end
    end

    context 'when the user has access to multiple libraries' do
      let(:patron) { Patron.new('fields' => { 'profile' => { 'key' => 'MXF' } }) }
      let(:dropdown) { Capybara.string(helper.schedule_once_link_or_dropdown) }

      it 'renders a dropdown to select each library' do
        expect(dropdown).to have_css('.schedule-dropdown button.dropdown-toggle', text: /Enter for research/)
      end

      it 'renders a link in the dropdown to Green Library' do
        expect(dropdown).to have_css('.schedule-dropdown .dropdown-menu a', text: 'Green Library')
      end

      it 'renders a link in the dropdown to East Asia Library' do
        expect(dropdown).to have_css('.schedule-dropdown .dropdown-menu a', text: 'East Asia Library')
      end
    end
  end

  context 'when scheduling a pickup' do
    let(:hold_record_list) do
      [
        { 'fields' => { 'status' => 'BEING_HELD', 'pickupLibrary' => { 'key' => 'GREEN' } } },
        { 'fields' => { 'status' => 'BEING_HELD', 'pickupLibrary' => { 'key' => 'BUSINESS' } } }
      ]
    end

    before do
      stub_request(:any, /rc\.relais-host\.com/).to_return(status: 200)
      helper.define_singleton_method(:patron_or_group, -> {}) # Define the helper we want to stub
      allow(helper).to receive(:patron_or_group).and_return(
        Patron.new('fields' => {
          'profile' => { 'key' => 'MXF' },
          'holdRecordList' => hold_record_list
        })
      )
    end

    describe '#link_to_schedule_pickup' do
      it 'is nil when the library being requested is available for puckups' do
        link = helper.link_to_schedule_pickup(library: 'NO-PICKUP', text: 'Anything')
        expect(link).to be_nil
      end

      it 'is a link with the appropriate data attributes' do
        link = helper.link_to_schedule_pickup(library: 'GREEN', text: 'Green Library')
        expect(link).to include 'data-mylibrary-modal="trigger"'
      end

      it 'uses the given text as the link text' do
        link = Capybara.string(helper.link_to_schedule_pickup(library: 'GREEN', text: 'Green Library'))
        expect(link).to have_link('Green Library', href: '/schedule/green_pickup')
      end

      it 'links to the appropriate href given the library' do
        link = helper.link_to_schedule_pickup(library: 'BUSINESS', text: 'Business Library')
        expect(link).to include 'href="/schedule/business_pickup"'
      end
    end

    describe '#schedule_pickup_link_or_dropdown' do
      context 'when no libraries are available for pickup' do
        let(:hold_record_list) { [] }

        it 'renders a disabled link' do
          expect(helper.schedule_pickup_link_or_dropdown).to have_css('a.disabled', text: 'Pick up requests')
        end
      end

      context 'when there is only one library available for pickup' do
        let(:hold_record_list) do
          [
            { 'fields' => { 'status' => 'BEING_HELD', 'pickupLibrary' => { 'key' => 'GREEN' } } }
          ]
        end

        it 'links directly to that library' do
          link = helper.schedule_pickup_link_or_dropdown
          expect(link).to have_link('Pick up requests at Green Library', href: '/schedule/green_pickup')
        end

        it 'does not have a dropdown' do
          link = helper.schedule_pickup_link_or_dropdown
          expect(link).not_to have_css('.dropdown')
        end
      end

      context 'when there are mutliple libraries available for pickup' do
        let(:hold_record_list) do
          [
            { 'fields' => { 'status' => 'BEING_HELD', 'pickupLibrary' => { 'key' => 'GREEN' } } },
            { 'fields' => { 'status' => 'BEING_HELD', 'pickupLibrary' => { 'key' => 'BUSINESS' } } }
          ]
        end

        it 'has a dropdown with options for each enabled library available for pickup' do
          dropdown = helper.schedule_pickup_link_or_dropdown
          expect(dropdown).to have_css('.dropdown')
        end

        it 'has a dropdown with a link for GREEN' do
          dropdown = helper.schedule_pickup_link_or_dropdown
          expect(dropdown).to have_css('.dropdown .dropdown-menu .dropdown-item', text: 'Green Library')
        end

        it 'has a dropdown with a link for BUSINESS' do
          dropdown = helper.schedule_pickup_link_or_dropdown
          expect(dropdown).to have_css('.dropdown .dropdown-menu .dropdown-item', text: 'Business Library')
        end
      end
    end
  end
end
