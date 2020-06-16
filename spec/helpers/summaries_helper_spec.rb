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

      it 'renders text indicating that the user is not eligible' do
        expect(helper.schedule_once_link_or_dropdown).to eq 'Not eligible during current phase of Research Restart Plan'
      end
    end

    context 'when the user has access to one library' do
      let(:patron) { Patron.new('fields' => { 'profile' => { 'key' => 'MXF' } }) }

      before do
        allow(Settings.schedule_once.eal_visits).to receive(:enabled).and_return(false)
      end

      it 'renders a single button to schedule a visit' do
        expect(
          Capybara.string(helper.schedule_once_link_or_dropdown)
        ).to have_link('🗓 Schedule access to Green Library', href: '/schedule/green')
      end
    end

    context 'when the user has access to multiple libraries' do
      let(:patron) { Patron.new('fields' => { 'profile' => { 'key' => 'MXF' } }) }
      let(:dropdown) { Capybara.string(helper.schedule_once_link_or_dropdown) }

      it 'renders a dropdown to select each library' do
        expect(dropdown).to have_css('.schedule-once-dropdown button.dropdown-toggle', text: '🗓 Schedule access to ...')
      end

      it 'renders a link in the dropdown to Green Library' do
        expect(dropdown).to have_css('.schedule-once-dropdown .dropdown-menu a', text: 'Green Library')
      end

      it 'renders a link in the dropdown to East Asia Library' do
        expect(dropdown).to have_css('.schedule-once-dropdown .dropdown-menu a', text: 'East Asia Library')
      end
    end
  end
end
