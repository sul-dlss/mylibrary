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
    it 'is a link with the appropriate data attributes' do
      link = link_to_schedule_once_visit(library: 'GREEN', text: 'Green Library')
      expect(link).to include 'data-mylibrary-modal="trigger"'
    end

    it 'links to the appropriate href given the library' do
      link = link_to_schedule_once_visit(library: 'EAST-ASIA', text: 'East Asia Library')
      expect(link).to include 'href="/schedule/eal"'
    end

    it 'uses the given text as the link text' do
      link = Capybara.string(link_to_schedule_once_visit(library: 'GREEN', text: 'Green Library'))
      expect(link).to have_link('Green Library', href: '/schedule/green')
    end
  end
end
