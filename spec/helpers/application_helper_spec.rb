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

  describe '#render_checkout_status' do
    let(:content) { Capybara.string(helper.render_checkout_status(checkout)) }

    context 'when a recalled item has accrued fines' do
      let(:checkout) { instance_double(Checkout, recalled?: true, accrued: 15) }

      it 'renders the right html' do
        expect(content).to have_css('.text-recalled', text: 'Recalled $15').and(have_css('.sul-icons'))
      end
    end

    context 'when a recalled item has no accrued fines' do
      let(:checkout) { instance_double(Checkout, recalled?: true, accrued: 0) }

      it 'renders the right html' do
        expect(content).to have_css('.text-recalled', text: 'Recalled').and(have_css('.sul-icons'))
      end
    end

    context 'when an item is lost' do
      let(:checkout) { instance_double(Checkout, recalled?: false, overdue?: true, lost?: true, accrued: 666) }

      it 'renders the right html' do
        expect(content).to have_css('.text-lost', text: 'Assumed lost $666').and(have_css('.sul-icons'))
      end
    end

    context 'when an overdue item has accrued fines' do
      let(:checkout) { instance_double(Checkout, recalled?: false, overdue?: true, lost?: false, accrued: 666) }

      it 'renders the right html' do
        expect(content).to have_css('.text-overdue', text: 'Overdue $666').and(have_css('.sul-icons'))
      end
    end

    context 'when an overdue item has no accrued fines' do
      let(:checkout) { instance_double(Checkout, recalled?: false, overdue?: true, lost?: false, accrued: 0) }

      it 'renders the right html' do
        expect(content).to have_css('.text-overdue', text: 'Overdue').and(have_css('.sul-icons'))
      end
    end
  end
end
