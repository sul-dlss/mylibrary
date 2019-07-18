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
    Time.zone.parse(fields['dueDate'])
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

  ##
  # Is this item renewable
  def renewable?
    Time.zone.now > renewable_at if renewable_at
  end

  ##
  # The date in which the item can be renewed
  def renewable_at
    due_date.to_date - renew_from_period.days if due_date && renew_from_period.positive?
  end

  ##
  # The period before the due date in which the item can be renewed
  def renew_from_period
    fields.dig('circulationRule', 'fields', 'renewFromPeriod').to_i
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
    fields['estimatedOverdueAmount']['amount'].to_d
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
end
