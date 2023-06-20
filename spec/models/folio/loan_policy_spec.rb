# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::LoanPolicy do
  subject(:folio_loan_policy) do
    described_class.new(loan_policy: loan_policy, due_date: due_date)
  end

  before do
    Timecop.freeze(Time.zone.local(2023, 6, 20, 7, 24, 2))
  end

  after do
    Timecop.return
  end

  describe '#too_soon_to_renew?' do
    describe 'schedule loan policy' do
      let(:loan_policy) do
        { 'loansPolicy' =>
           { 'fixedDueDateSchedule' => { 'description' => 'Annual loans',
                                         'id' => '277410e1-2908-4e2b-bf96-ac81b4aedad4',
                                         'name' => 'Annual due date schedule',
                                         'schedules' =>
            [{ 'due' => '2023-07-01T06:59:59.000+00:00',
               'from' => '1993-02-01T08:00:00.000+00:00',
               'to' => '2023-05-01T06:59:59.000+00:00' },
             { 'due' => '2024-07-02T06:59:59.000+00:00',
               'from' => '2023-05-01T07:00:00.000+00:00',
               'to' => '2024-05-01T06:59:59.000+00:00' }] },
             'period' => nil },
          'renewalsPolicy' =>
           { 'renewFromId' => nil,
             'period' => nil,
             'alternateFixedDueDateSchedule' => nil } }
      end

      context 'when renewal would not extend the due date' do
        let(:due_date) { Date.parse('2024-07-02T06:59:59.000+00:00') }

        it { expect(folio_loan_policy.too_soon_to_renew?).to be true }
      end

      context 'when renewal would extend the due date' do
        let(:due_date) { Date.parse('2023-07-02T06:59:59.000+00:00') }

        it { expect(folio_loan_policy.too_soon_to_renew?).to be false }
      end
    end

    describe 'alternate schedule loan policy' do
      let(:loan_policy) do
        { 'loansPolicy' =>
           { 'fixedDueDateSchedule' => { 'description' => 'Annual loans',
                                         'id' => '277410e1-2908-4e2b-bf96-ac81b4aedad4',
                                         'name' => 'Annual due date schedule',
                                         'schedules' =>
            [{ 'due' => '2023-07-01T06:59:59.000+00:00',
               'from' => '1993-02-01T08:00:00.000+00:00',
               'to' => '2023-05-01T06:59:59.000+00:00' },
             { 'due' => '2024-07-02T06:59:59.000+00:00',
               'from' => '2023-05-01T07:00:00.000+00:00',
               'to' => '2024-05-01T06:59:59.000+00:00' }] },
             'period' => nil },
          'renewalsPolicy' =>
           { 'renewFromId' => nil,
             'period' => nil,
             'alternateFixedDueDateSchedule' => { 'description' => 'Alternate annual loans',
                                                  'id' => '277410e1-2908-4e2b-bf96-ac81b4aedad4',
                                                  'name' => 'Annual due date schedule',
                                                  'schedules' =>
              [{ 'due' => '2004-07-02T06:59:59.000+00:00',
                 'from' => '2003-05-01T07:00:00.000+00:00',
                 'to' => '2004-05-01T06:59:59.000+00:00' }] } } }
      end

      # NOTE: Setting the current time further in the past so it falls
      #       within the range of the alternate schedule.
      before do
        Timecop.freeze(Time.zone.local(2003, 6, 20, 7, 24, 2))
      end

      context 'when renewal would extend the due date' do
        let(:due_date) { Date.parse('2003-07-02T06:59:59.000+00:00') }

        it { expect(folio_loan_policy.too_soon_to_renew?).to be false }
      end
    end

    describe 'period loan policy where renewal is calculated from the current time' do
      let(:loan_policy) do
        { 'loansPolicy' =>
          { 'fixedDueDateSchedule' => nil,
            'period' => { 'intervalId' => 'Weeks', 'duration' => 20 } },
          'renewalsPolicy' =>
          { 'renewFromId' => 'SYSTEM_DATE',
            'period' => nil,
            'alternateFixedDueDateSchedule' => nil } }
      end

      context 'when renewal would not extend the due date' do
        let(:due_date) { Date.parse('2024-07-02T06:59:59.000+00:00') }

        it { expect(folio_loan_policy.too_soon_to_renew?).to be true }
      end

      context 'when renewal would extend the due date' do
        let(:due_date) { Date.parse('2023-07-02T06:59:59.000+00:00') }

        it { expect(folio_loan_policy.too_soon_to_renew?).to be false }
      end
    end

    describe 'period renew policy where renewal is calculated from the current time' do
      let(:loan_policy) do
        { 'loansPolicy' =>
          { 'fixedDueDateSchedule' => nil,
            'period' => { 'intervalId' => 'Weeks', 'duration' => 20 } },
          'renewalsPolicy' =>
          { 'renewFromId' => 'SYSTEM_DATE',
            'period' => { 'intervalId' => 'Weeks', 'duration' => 1 },
            'alternateFixedDueDateSchedule' => nil } }
      end
      let(:due_date) { Date.parse('2023-06-30T06:59:59.000+00:00') }

      context 'when renewal would not extend the due date' do
        it { expect(folio_loan_policy.too_soon_to_renew?).to be true }
      end
    end

    describe 'period loan policy where renewal is calculated from current due date' do
      let(:loan_policy) do
        { 'loansPolicy' =>
          { 'fixedDueDateSchedule' => nil,
            'period' => { 'intervalId' => 'Weeks', 'duration' => 20 } },
          'renewalsPolicy' =>
          { 'renewFromId' => 'CURRENT_DUE_DATE',
            'period' => nil,
            'alternateFixedDueDateSchedule' => nil } }
      end
      let(:due_date) { Date.parse('2024-07-02T06:59:59.000+00:00') }

      context 'when renewal would extend the due date' do
        it { expect(folio_loan_policy.too_soon_to_renew?).to be false }
      end
    end
  end
end
