# frozen_string_literal: true

# Model for the Checkouts page
class Checkout
  attr_reader :record

  SHORT_TERM_LOAN_PERIODS = %w[HOURLY].freeze

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def status
    fields['status']
  end

  def due_date
    fields['dueDate'] && Time.zone.parse(fields['dueDate'])
  end

  def days_overdue
    return 0 unless overdue?

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

  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
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

    'Too soon to renew.' unless renewable_at&.past?
  end
  # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

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

  def resource
    fields['item']['resource']
  end

  def item_key
    fields['item']['key']
  end

  def overdue?
    fields['overdue']
  end

  def accrued
    fields.dig('estimatedOverdueAmount', 'amount').to_d
  end

  def days_remaining
    return 0 if overdue?

    (due_date.to_date - Time.zone.now.to_date).to_i
  end

  def library
    fields['library']['key']
  end

  def catkey
    fields['item']['fields']['bib']['key']
  end

  def title
    bib['title']
  end

  def author
    bib['author']
  end

  def call_number
    call['dispCallNumber']
  end

  def shelf_key
    call['sortCallNumber']
  end

  def short_term_loan?
    SHORT_TERM_LOAN_PERIODS.include?(loan_period_type)
  end

  def to_partial_path
    'checkouts/checkout'
  end

  def current_location
    fields.dig('item', 'fields', 'currentLocation', 'key')
  end

  def lost?
    current_location == 'LOST-ASSUM'
  end

  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  def sort_key(key)
    sort_key = case key
               when :status
                 [status_sort_key, title, author, shelf_key]
               when :due_date
                 [due_date.strftime('%FT%T'), title, author, shelf_key]
               when :title
                 [title, author, shelf_key]
               when :author
                 [author, title, shelf_key]
               when :call_number
                 [shelf_key]
               end

    sort_key.join('---')
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
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

  private

  def fields
    record['fields']
  end

  def loan_period_type
    fields.dig('circulationRule', 'fields', 'loanPeriod', 'fields', 'periodType', 'key')
  end

  def bib
    fields['item']['fields']['bib']['fields']
  end

  def call
    fields['item']['fields']['call']['fields']
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
end
