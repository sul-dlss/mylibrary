# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutsHelper do
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

  describe '#today_with_time_or_date' do
    context 'when the checkout is a short term loan' do
      it 'returns a string that says Today and the time' do
        expect(helper.today_with_time_or_date(Time.zone.now + 42.minutes, short_term: true)).to match(/^Today at \d/)
      end

      context 'when the due date is on a past date' do
        it 'returns a formatted date' do
          expect(
            helper.today_with_time_or_date(Time.zone.parse('2019-01-01'), short_term: true)
          ).to eq 'January  1, 2019'
        end
      end
    end

    context 'when the short term flag is false' do
      it 'returns a formatted date' do
        expect(helper.today_with_time_or_date(Time.zone.parse('2019-01-01'))).to eq 'January  1, 2019'
      end
    end
  end
end
