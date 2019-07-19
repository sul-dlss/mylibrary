# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#active_page_class' do
    it 'when the controller_name matches the provided name' do
      allow(helper).to receive(:controller_name).and_return 'summaries'
      expect(helper.active_page_class('summaries')).to eq 'active'
    end
    it 'when the controller_name does not match' do
      expect(helper.active_page_class('summaries')).to be_nil
    end
  end

  describe '#detail_link_to_searchworks' do
    let(:content) { Capybara.string(helper.detail_link_to_searchworks('12345')) }

    it 'has two columns' do
      expect(content).to have_css('.row .col-5', count: 2)
    end

    it 'has a link to SerachWorks' do
      expect(content).to have_link(text: /View in SearchWorks/, href: %r{/view/12345$})
    end
  end

  describe '#sul_icon' do
    it 'wraps the svg in a span with classes' do
      expect(helper.sul_icon(:renew))
        .to have_css 'span.sul-icons svg'
    end
  end

  describe '#library_name' do
    it 'translates the code to a human-readable name' do
      expect(helper.library_name('GREEN')).to eq 'Green Library'
    end

    it 'falls back on the code' do
      expect(helper.library_name('NOSUCHLIBRARY')).to eq 'NOSUCHLIBRARY'
    end
  end
end
