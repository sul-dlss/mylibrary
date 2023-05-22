# frozen_string_literal: true

# Model for a Payment on the Fine page
class Payment
  attr_reader :record

  PAYMENT_TYPES = {
    'AUTOREFUND' => 'Returned',
    'CANCEL' => 'Removed',
    'CARDSWIPE' => 'Paid by credit card',
    'CASH' => 'Paid by cash',
    'CHECK' => 'Paid by check',
    'CLMS-RTND' => 'Processing claim',
    'CREDITACCT' => 'Returned',
    'CREDITCARD' => 'Paid by credit card',
    'FORGIVEN' => 'Forgiven',
    'LIB-ERROR' => 'Removed',
    'NONE' => 'Returned',
    'REFUND' => 'Removed',
    'RETURNED' => 'Returned',
    'TRANS-BILL' => 'Forgiven',
    'U-REPLACED' => 'Replacement provided',
    'XREMBILL' => 'Removed'
  }.freeze

  BILL_REASONS = {
    'OVERDUE' => 'Overdue item',
    'RECALLOVD' => 'Overdue recall',
    'RESERVEOVD' => 'Overdue course reserve',
    'LOST' => 'Lost item',
    'REPLCMENT' => 'Lost item',
    'LOST-ILL' => 'Lost interlibrary loan item',
    'CLAIM-LOST' => 'Lost item',
    'CLAIM-FEE' => 'Processing fee',
    'PROCESSFEE' => 'Processing fee',
    'PROCESSING' => 'Processing fee',
    'DAMAGED' => 'Damaged item',
    'PRIVILEGES' => 'Privileges fee',
    'LOSTCARD' => 'Lost card fee',
    'LOSTKEY' => 'Lost key fee'
  }.freeze

  def initialize(record)
    @record = record
  end

  def key
    record['billNumber']
  end

  def bill_description
    record['billReasonDescription']
  end

  def nice_bill_description
    BILL_REASONS[bill_reason_id]
  end

  def bill_amount
    record['amount']
  end

  def bill_date
    Time.strptime(record['dateBilled'], '%Y-%m-%d')
  end

  def item_title
    (fee_item_info && fee_item_info['title']) || 'No item associated with this payment'
  end

  def item_library
    fee_item_info && fee_item_info['itemLibraryID']
  end

  def payment_amount
    fee_pay_info && fee_pay_info['paymentAmount']
  end

  def payment_date
    fee_pay_info && fee_pay_info['paymentDate'] && Time.strptime(fee_pay_info['paymentDate'], '%Y-%m-%d')
  end

  def resolution
    return PAYMENT_TYPES.fetch(fee_pay_info['paymentTypeID'], '') if PAYMENT_TYPES.key?(fee_pay_info['paymentTypeID'])

    'Unknown'
  end

  def paid_fee?
    %w[CASH CHECK CREDITCARD].include? fee_pay_info['paymentTypeID']
  end

  def to_partial_path
    'payments/payment'
  end

  # rubocop:disable Metrics/MethodLength
  def sort_key(key)
    sort_key = case key
               when :payment_date
                 [payment_sort_key, item_title, nice_bill_description]
               when :item_title
                 [item_title, payment_sort_key, nice_bill_description]
               when :bill_amount
                 [bill_amount, payment_sort_key, item_title, nice_bill_description]
               when :bill_description
                 [nice_bill_description, payment_sort_key, item_title]
               end

    sort_key.join('---')
  end
  # rubocop:enable Metrics/MethodLength

  # Sort payments by date in descending order
  def payment_sort_key
    return Request::END_OF_DAYS - payment_date if payment_date

    0
  end

  private

  def fee_pay_info
    Array.wrap(record['feePaymentInfo']).first
  end

  def fee_item_info
    record['feeItemInfo']
  end

  def bill_reason_id
    record['billReasonID']
  end
end
