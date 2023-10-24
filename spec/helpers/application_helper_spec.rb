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

  describe '#today_with_time_or_date' do
    context 'when the checkout is a short term loan' do
      it 'returns a string that says Today and the time' do
        date = Time.zone.today.at_end_of_day

        expect(helper.today_with_time_or_date(date, short_term: true))
          .to match(/^Today at\s{1,2}\d/)
      end

      it 'returns a string that says Tomorrow and the time' do
        date = Time.zone.tomorrow.at_end_of_day

        expect(helper.today_with_time_or_date(date, short_term: true))
          .to match(/^Tomorrow at\s{1,2}\d/)
      end

      context 'when the due date is on a past date' do
        it 'returns a formatted date' do
          expect(
            helper.today_with_time_or_date(Time.zone.parse('2019-01-01'), short_term: true)
          ).to eq 'January  1, 2019'
        end
      end
    end

    it 'returns a formatted date' do
      expect(helper.today_with_time_or_date(Time.zone.parse('2019-01-01'))).to eq 'January  1, 2019'
    end

    context 'with a time from today' do
      it 'returns "Today"' do
        expect(helper.today_with_time_or_date(Time.zone.now)).to eq 'Today'
      end
    end

    context 'with a time from tomorrow' do
      it 'returns "Tomorrow"' do
        expect(helper.today_with_time_or_date(1.day.from_now)).to eq 'Tomorrow'
      end
    end

    context 'with a time from yesterday' do
      it 'returns "Yesterday"' do
        expect(helper.today_with_time_or_date(1.day.ago)).to eq 'Yesterday'
      end
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

    context 'without a catkey' do
      it 'returns nothing' do
        expect(helper.detail_link_to_searchworks(nil)).to be_nil
      end
    end
  end

  describe '#sul_icon' do
    it 'wraps the svg in a span with classes' do
      expect(helper.sul_icon(:renew))
        .to have_css 'span.sul-icons svg'
    end
  end

  describe '#library_email' do
    it 'translates the code to a an email' do
      expect(helper.library_email('EARTH-SCI')).to eq 'brannerlibrary@stanford.edu'
    end

    it 'falls back to greencirc' do
      expect(helper.library_email('NOSUCHLIBRARY')).to eq 'greencirc@stanford.edu'
    end
  end

  describe '#proxy_login_header' do
    it 'returns the expected text' do
      expect(helper.proxy_login_header).to eq 'Proxy, fee, or courtesy accounts'
    end
  end
end
