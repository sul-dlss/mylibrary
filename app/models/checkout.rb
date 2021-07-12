# frozen_string_literal: true

# Model for the Checkouts page
class Checkout
  include BibRecord

  attr_reader :record

  SHORT_TERM_LOAN_PERIODS = %w[HOURLY].freeze

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
    record['key']
  end

  def status
    fields['status']
  end

  def due_date
    recall_due_date || original_due_date
  end

  def days_overdue
    return 0 unless overdue?
    return 0 if due_date.nil?

    ((Time.zone.now - due_date).to_i / 60 / 60 / 24) + 1
  end

  def checkout_date
    Time.zone.parse(fields['checkOutDate'])
  end

  def recalled_date
    Time.zone.parse(fields['recalledDate']) if fields['recalledDate']
  end

  def recalled?
    recalled_date.present?
  end

  def claims_returned_date
    Time.zone.parse(fields['claimsReturnedDate']) if fields['claimsReturnedDate']
  end

  def claimed_returned?
    claims_returned_date.present?
  end

  def renewal_date
    Time.zone.parse(fields['renewalDate']) if fields['renewalDate']
  end

  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
  def non_renewable_reason
    return 'Item is assumed lost; you must pay the fee or return the item.' if lost?
    return 'No. Another user is waiting for this item.' if recalled?
    return 'No. Claim review is in process.' if claimed_returned?

    if unseen_renewals_remaining.zero?
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
    item.dig('itemCategory5', 'key') == 'NORENEW'
  end

  def renewable?
    non_renewable_reason.blank?
  end

  ##
  # The date in which the item can be renewed (i.e too soon to renew)
  def renewable_at
    due_date.to_date - renew_from_period.days if due_date && renew_from_period.positive?
  end

  ##
  # The period before the due date in which the item can be renewed
  def renew_from_period
    fields.dig('circulationRule', 'fields', 'renewFromPeriod').to_i
  end

  def patron_key
    fields['patron']['key']
  end

  def overdue?
    fields['overdue']
  end

  def accrued
    fields.dig('estimatedOverdueAmount', 'amount').to_d
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

  private

  def fields
    record['fields']
  end

  def loan_period_type
    fields.dig('circulationRule', 'fields', 'loanPeriod', 'fields', 'periodType', 'key')
  end

  def circulation_rule
    fields.dig('circulationRule', 'key')
  end

  def reserve_item?
    circulation_rule&.end_with?('-RES')
  end

  def renewal_count
    fields['renewalCount'] || 0
  end

  # nil means "unlimited" for unseenRenewalsRemaining
  def unseen_renewals_remaining
    fields['unseenRenewalsRemaining'] || Float::INFINITY
  end

  # nil means "unlimited" for seenRenewalsRemaining
  def seen_renewals_remaining
    fields['seenRenewalsRemaining'] || Float::INFINITY
  end

  def original_due_date
    fields['dueDate'] && Time.zone.parse(fields['dueDate'])
  end

  def recall_due_date
    fields['recallDueDate'] && Time.zone.parse(fields['recallDueDate'])
  end

  def library_key
    fields&.dig('library', 'key')
  end

  def from_ilb?
    item_type&.starts_with? 'ILB'
  end

  def from_borrow_direct?
    item_type == 'BORROWDIR'
  end

  def item_type
    fields.dig('item', 'fields', 'itemType', 'key')
  end
end
