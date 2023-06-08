# frozen_string_literal: true

module Folio
  # ? FOLIO: Checkout = "Loan" in Folio - consider renaming for clarity
  class Checkout
    include Folio::FolioRecord

    attr_reader :record

    SHORT_TERM_LOAN_PERIODS = %w[Hours Minutes].freeze

    def initialize(record, cdl: false)
      @record = record
      @cdl = cdl
    end

    def self.find(key, **args)
      symphony_client = SymphonyClient.new
      new(symphony_client.circ_record_info(key), **args)
    rescue HTTP::Error
      nil
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

    def recalled_date
      # TODO: unclear if FOLIO keeps this information
      nil
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

    def renewal_date
      # TODO: unclear if FOLIO keeps this information
      nil
    end

    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    def non_renewable_reason
      return 'Item is assumed lost; you must pay the fee or return the item.' if lost?
      return 'No. Another user is waiting for this item.' if recalled?
      return 'No. Claim review is in process.' if claimed_returned?

      unless unseen_renewals_remaining.positive?
        return 'No online renewals left; you may renew this item in person.' if renewal_count.positive?

        return 'No online renewals for this item.'
      end

      return 'No renewals left for this item.' if seen_renewals_remaining.zero?
      return 'Renew Reserve items in person.' if reserve_item?
      return 'No. Another user is waiting for this item.' if item_category_non_renewable?

      'Too soon to renew.' unless renewable_at&.past?
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength

    def item_category_non_renewable?
      record.dig('details', 'loanPolicy', 'renewable') == false
    end

    def renewable?
      non_renewable_reason.blank?
    end

    ##
    # The date in which the item can be renewed (i.e too soon to renew)
    def renewable_at
      Time.zone.now.to_date
      # due_date.to_date - renew_from_period.days if due_date && renew_from_period.positive?
    end

    ##
    # The period before the due date in which the item can be renewed
    def renew_from_period
      nil
      # fields.dig('circulationRule', 'fields', 'renewFromPeriod').to_i
    end

    def patron_key
      record.dig('details', 'proxyUserId') || record.dig('details', 'userId')
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

    def library
      if from_borrow_direct?
        Settings.BORROW_DIRECT_CODE
      elsif from_ill?
        Settings.ILL_CODE
      else
        # In some edge cases Symws returns an empty block for fields['library']
        library_key || 'Stanford Libraries'
      end
    end

    def from_ill?
      (library_key == 'SUL') || from_borrow_direct? || from_ilb?
    end

    def short_term_loan?
      SHORT_TERM_LOAN_PERIODS.include?(loan_period_type) || @cdl
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
      record.dig('details', 'declaredLostDate')
    end

    def barcode
      record.dig('item', 'item', 'barcode')
    end

    private

    def loan_period_type
      record.dig('details', 'loanPolicy', 'loansPolicy', 'period', 'intervalId')
    end

    def circulation_rule
      nil
      # fields.dig('circulationRule', 'key')
    end

    def reserve_item?
      nil
      # circulation_rule&.end_with?('-RES')
    end

    def renewal_count
      record.dig('details', 'renewalCount') || 0
    end

    def unseen_renewals_remaining
      unseen_renewals_allowed - renewal_count
    end

    def unseen_renewals_allowed
      record.dig('details', 'loanPolicy', 'renewalsPolicy', 'numberAllowed') || 0
    end

    def seen_renewals_remaining
      Float::INFINITY
    end

    def library_key
      nil
      # fields&.dig('library', 'key')
    end

    def from_ilb?
      item_type&.starts_with? 'ILB'
    end

    def from_borrow_direct?
      item_type == 'BORROWDIR'
    end

    def item_type
      nil
      # fields.dig('item', 'fields', 'itemType', 'key')
    end
  end
end
