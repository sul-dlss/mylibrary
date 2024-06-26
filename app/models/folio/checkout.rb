# frozen_string_literal: true

module Folio
  # ? FOLIO: Checkout = "Loan" in Folio - consider renaming for clarity
  class Checkout
    include Folio::FolioRecord

    attr_reader :record, :patron_type_id

    delegate :loan_policy_interval,
             :too_soon_to_renew?,
             :renewal_blocked_by_hold?,
             :unseen_renewals_remaining,
             :seen_renewals_remaining,
             to: :loan_policy,
             private: true

    SHORT_TERM_LOAN_PERIODS = %w[Hours Minutes].freeze
    FOLIO_LOST_STATUSES = ['Aged to lost', 'Declared lost'].freeze

    def initialize(record, patron_type_id)
      @record = record
      @patron_type_id = patron_type_id
    end

    def key
      record['id']
    end

    def status
      record.dig('details', 'status', 'name')
    end

    def due_date
      Time.zone.parse(record['dueDate'])
    end

    def days_overdue
      return 0 unless overdue?
      return 0 if due_date.nil?

      ((Time.zone.now - due_date).to_i / 60 / 60 / 24) + 1
    end

    def checkout_date
      Time.zone.parse(record['loanDate'])
    end

    def recalled?
      record.dig('details', 'dueDateChangedByRecall') || record.dig('details', 'dueDateChangedByHold')
    end

    def claims_returned_date
      claimed_returned? && Time.zone.parse(record.dig('item', 'item', 'status', 'date'))
    end

    def claimed_returned?
      record.dig('item', 'item', 'status', 'name') == 'Claimed returned'
    end

    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    def non_renewable_reason
      return 'Item is assumed lost; you must pay the fee or return the item.' if lost?
      return 'No. Another user is waiting for this item.' if recalled? || renewal_blocked_by_hold?
      return 'No. Claim review is in process.' if claimed_returned?

      unless unseen_renewals_remaining.positive?
        return 'No online renewals left; you may renew this item in person.' if renewal_count.positive?

        return 'No online renewals for this item.'
      end

      return 'No renewals left for this item.' if seen_renewals_remaining.zero?
      return 'Renew Reserve items in person.' if reserve_item?
      return 'No. Another user is waiting for this item.' if item_category_non_renewable?

      'Too soon to renew.' if too_soon_to_renew?
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength

    def item_category_non_renewable?
      !loan_policy.renewable?
    end

    def renewable?
      non_renewable_reason.blank?
    end

    def patron_key
      record.dig('details', 'proxyUserId') || record.dig('details', 'userId')
    end

    # @return [Boolean] Returns true if the proxyUserId exists
    def proxy_checkout?
      record.dig('details', 'proxyUserId').present?
    end

    def overdue?
      record['overdue']
    end

    def accrued
      record.dig('details', 'feesAndFines', 'amountRemainingToPay') || 0.0
    end

    def days_remaining
      return 0 if overdue?
      return -1 if due_date.nil?

      (due_date.to_date - Time.zone.now.to_date).to_i
    end

    def short_term_loan?
      SHORT_TERM_LOAN_PERIODS.include?(loan_policy_interval)
    end

    def to_partial_path
      'checkouts/checkout'
    end

    # rubocop:disable Metrics/MethodLength
    def sort_key(key)
      sort_key = case key
                 when :status
                   [status_sort_key, title, author, shelf_key]
                 when :due_date
                   [due_date_sort_value, title, author, shelf_key]
                 when :title
                   [title, author, shelf_key]
                 when :author
                   [author, title, shelf_key]
                 when :call_number
                   [shelf_key]
                 end

      sort_key.join('---')
    end

    def due_date_sort_value
      due_date&.strftime('%FT%T') || ''
    end

    def status_sort_key
      if recalled?
        0
      elsif lost?
        1
      elsif claimed_returned?
        4
      elsif accrued.positive?
        2
      elsif overdue?
        3
      else
        9
      end
    end
    # rubocop:enable Metrics/MethodLength

    def lost?
      FOLIO_LOST_STATUSES.include?(record.dig('item', 'item', 'status', 'name'))
    end

    def barcode
      record.dig('item', 'item', 'barcode')
    end

    private

    def loan_policy
      @loan_policy ||= Folio::LoanPolicy.new(loan_policy: effective_loan_policy,
                                             due_date:,
                                             renewal_count:,
                                             hold_queue_length:)
    end

    def effective_loan_policy
      @effective_loan_policy ||= Folio::Types.loan_policies.fetch(effective_loan_policy_id) do
        Honeybadger.notify('Unable to find loan policy for checkout',
                           context: { key:, effective_loan_policy_id: })
        {}
      end
    end

    # NOTE: We need to fetch the latest loan policy to evaluate renewability. The loan policy returned
    # with the loan is the policy at the time of checkout and could have changed in ways that impact
    # eligibility for renewal.
    def effective_loan_policy_id # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      cache_key = ['effective_loan_policy_id', item_type_id, loan_type_id, patron_type_id, location_id].join(':')
      Rails.cache.fetch(cache_key, expires_in: 1.day) do
        response = FolioClient.new.find_effective_loan_policy(item_type_id:,
                                                              loan_type_id:,
                                                              patron_type_id:,
                                                              location_id:)

        unless response['loanPolicyId']
          Honeybadger.notify('Unable to find effective loan policy for checkout',
                             context: { key:, cache_key:, response: })
        end

        response['loanPolicyId']
      end
    end

    def location_id
      record.dig('item', 'item', 'effectiveLocationId')
    end

    def loan_type_id
      record.dig('item', 'item', 'temporaryLoanTypeId') ||
        record.dig('item', 'item', 'permanentLoanTypeId')
    end

    def item_type_id
      record.dig('item', 'item', 'materialTypeId')
    end

    def reserve_item?
      /reserves?/i.match?(loan_policy.description)
    end

    def renewal_count
      record.dig('details', 'renewalCount') || 0
    end

    def hold_queue_length
      record.dig('item', 'item', 'queueTotalLength') || 0
    end
  end
end
