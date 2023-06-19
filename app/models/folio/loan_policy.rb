# frozen_string_literal: true

module Folio
  class LoanPolicy
    attr_reader :loan_policy, :due_date

    def initialize(loan_policy:, due_date:)
      @loan_policy = loan_policy
      @due_date = due_date
    end

    # Renewing would not extend the due date
    def too_soon_to_renew?
      due_date_after_renewal <= due_date
    end

    private

    def due_date_after_renewal
      if schedule_policy
        due_date_from_schedule
      elsif renewal_calculated_from_system_date?
        Time.zone.now + renewal_duration
      elsif renewal_calculated_from_due_date?
        due_date + renewal_duration
      end
    end

    def due_date_from_schedule
      schedule = schedule_policy.find do |policy|
        Time.zone.now.between?(policy['from'], policy['to'])
      end

      schedule['due'] if schedule
    end

    def schedule_policy
      effective_loan_policy_schedule&.map do |schedule|
        schedule.transform_values { |v| Date.parse(v) }
      end
    end

    def effective_loan_policy_schedule
      renewal_policy_schedule || loan_policy_schedule
    end

    def loan_policy_schedule
      loan_policy.dig('loansPolicy', 'fixedDueDateSchedule', 'schedules')
    end

    def renewal_policy_schedule
      loan_policy.dig('renewalsPolicy', 'alternateFixedDueDateSchedule', 'schedules')
    end

    def renewal_calculated_from_system_date?
      loan_policy.dig('renewalsPolicy', 'renewFromId') == 'SYSTEM_DATE'
    end

    def renewal_calculated_from_due_date?
      loan_policy.dig('renewalsPolicy', 'renewFromId') == 'CURRENT_DUE_DATE'
    end

    # rubocop:disable Metrics/MethodLength
    def renewal_duration
      case effective_policy_interval
      when 'Months'
        effective_policy_duration.months
      when 'Weeks'
        effective_policy_duration.weeks
      when 'Days'
        effective_policy_duration.days
      when 'Hours'
        effective_policy_duration.hours
      when 'Minutes'
        effective_policy_duration.minutes
      end
    end
    # rubocop:enable Metrics/MethodLength

    def effective_policy_interval
      renewals_policy_interval || loan_policy_interval
    end

    def effective_policy_duration
      renewals_policy_duration || loan_policy_duration
    end

    def renewals_policy_interval
      loan_policy.dig('renewalsPolicy', 'period', 'intervalId')
    end

    def renewals_policy_duration
      loan_policy.dig('renewalsPolicy', 'period', 'duration')
    end

    def loan_policy_interval
      loan_policy.dig('loansPolicy', 'period', 'intervalId')
    end

    def loan_policy_duration
      loan_policy.dig('loansPolicy', 'period', 'duration')
    end
  end
end
