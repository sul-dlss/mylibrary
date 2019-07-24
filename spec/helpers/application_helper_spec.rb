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
      expect(content).to have_css('.row .col-11')
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

  describe '#render_resource_icon' do
    it 'does not render anything if format data is not present' do
      expect(helper.render_resource_icon(nil)).to be_nil
    end

    it 'renders a book before a database' do
      actual = Capybara.string(helper.render_resource_icon(%w['Database Book']))
      expect(actual).to have_css('.sul-icons.sul-icon-book-open-4')
    end

    it 'renders an image before a book' do
      actual = Capybara.string(helper.render_resource_icon(%w['Book Image']))
      expect(actual).to have_css('.sul-icons.sul-icon-picture-2')
    end

    it 'renders the first resource type icon' do
      actual = Capybara.string(helper.render_resource_icon(%w['Video Image']))
      expect(actual).to have_css('.sul-icons.sul-icon-camera-film-1')
    end

    it 'renders an icon that is in the icon mapping' do
      actual = Capybara.string(helper.render_resource_icon(['Book']))
      expect(actual).to have_css('.sul-icons.sul-icon-book-open-4')
    end

    it 'does not render anything for something not in our icon mapping' do
      expect(helper.render_resource_icon(['iPad'])).to be_nil
    end
  end
end
