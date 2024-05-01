# frozen_string_literal: true

module Folio
  class LoanPolicy
    attr_reader :loan_policy, :due_date, :renewal_count

    def initialize(loan_policy:, due_date:, renewal_count:)
      @loan_policy = loan_policy
      @due_date = due_date
      @renewal_count = renewal_count
    end

    def loan_policy_interval
      loan_policy.dig('loansPolicy', 'period', 'intervalId')
    end

    def renewable?
      loan_policy['renewable']
    end

    # Renewing would not extend the due date
    def too_soon_to_renew?
      due_date_after_renewal <= due_date
    end

    # Unseen renewals are initiated by the patron online
    def unseen_renewals_remaining
      return Float::INFINITY if unlimited_renewals?

      unseen_renewals_allowed - renewal_count
    end

    # Seen renewals are initiated by the patron in person with library staff
    def seen_renewals_remaining
      Float::INFINITY
    end

    def description
      loan_policy['description']
    end

    private

    def due_date_after_renewal
      if schedule_policy
        due_date_from_schedule || due_date
      elsif renewal_calculated_from_system_date?
        Time.zone.now + renewal_duration
      elsif renewal_calculated_from_due_date?
        due_date + renewal_duration
      else
        due_date
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

    def loan_policy_duration
      loan_policy.dig('loansPolicy', 'period', 'duration')
    end

    def unlimited_renewals?
      loan_policy.dig('renewalsPolicy', 'unlimited') || false
    end

    def unseen_renewals_allowed
      loan_policy.dig('renewalsPolicy', 'numberAllowed') || 0
    end
  end
end
