# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutsHelper do
  describe '#list_group_item_status_for_checkout' do
    context 'with a recalled item' do
      let(:checkout) { instance_double(Checkout, recalled?: true) }

      it 'is *-danger' do
        expect(helper.list_group_item_status_for_checkout(checkout)).to eq 'list-group-item-danger'
      end
    end

    context 'with an overdue item' do
      let(:checkout) { instance_double(Checkout, recalled?: false, overdue?: true) }

      it 'is *-warning' do
        expect(helper.list_group_item_status_for_checkout(checkout)).to eq 'list-group-item-warning'
      end
    end
  end

  describe '#time_remaining_for_checkout' do
    context 'when the checkout is a short term loan' do
      let(:checkout) { instance_double(Checkout, short_term_loan?: true, due_date: Time.zone.now + 42.minutes) }

      it 'returns the distance of time in words' do
        expect(helper.time_remaining_for_checkout(checkout)).to eq '42 minutes'
      end
    end

    context 'when the checkout is not a short term loan' do
      let(:checkout) { instance_double(Checkout, short_term_loan?: false, days_remaining: 42) }

      it 'pluralizes the number of days remaining' do
        expect(helper.time_remaining_for_checkout(checkout)).to eq '42 days'
      end
    end
  end

  describe '#render_checkout_status' do
    let(:checkout) do
      instance_double(
        Checkout,
        recalled?: false,
        overdue?: false,
        lost?: false,
        claimed_returned?: false,
        accrued: 0
      )
    end
    let(:content) { Capybara.string(helper.render_checkout_status(checkout)) }

    context 'when a recalled item has accrued fines' do
      before do
        allow(checkout).to receive_messages(recalled?: true, accrued: 15)
      end

      it 'renders the right html' do
        expect(content).to have_css('.text-recalled', text: 'Recalled $15').and(have_css('.sul-icons'))
      end
    end

    context 'when a recalled item has no accrued fines' do
      before do
        allow(checkout).to receive_messages(recalled?: true)
      end

      it 'renders the right html' do
        expect(content).to have_css('.text-recalled', text: 'Recalled').and(have_css('.sul-icons'))
      end
    end

    context 'when an item is claimed returned' do
      before do
        allow(checkout).to receive_messages(overdue?: true, lost?: true, claimed_returned?: true, accrued: 666)
      end

      it 'renders the right html' do
        expect(content).to have_text('Processing claim')
      end
    end

    context 'when an item is lost' do
      before do
        allow(checkout).to receive_messages(overdue?: true, lost?: true, accrued: 666)
      end

      it 'renders the right html' do
        expect(content).to have_css('.text-lost', text: 'Assumed lost $666').and(have_css('.sul-icons'))
      end
    end

    context 'when an overdue item has accrued fines' do
      before do
        allow(checkout).to receive_messages(overdue?: true, accrued: 666)
      end

      it 'renders the right html' do
        expect(content).to have_css('.text-overdue', text: 'Overdue $666').and(have_css('.sul-icons'))
      end
    end

    context 'when an overdue item has no accrued fines' do
      before do
        allow(checkout).to receive_messages(overdue?: true)
      end

      it 'renders the right html' do
        expect(content).to have_css('.text-overdue', text: 'Overdue').and(have_css('.sul-icons'))
      end
    end

    context 'when an item is not deliquent' do
      it 'renders the right html' do
        expect(content).to have_text('OK')
      end
    end
  end
end
