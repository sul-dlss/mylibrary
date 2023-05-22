# frozen_string_literal: true

# Model for the Fine page
class Fine
  include BibRecord

  attr_reader :record

  FINE_STATUS = {
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
    'LOSTKEY' => 'Lost key fee',
    'BILLED-OD' => 'Lost item',
    'BILLING-FEE' => 'Processing fee',
    'PRE-NOTIS' => 'Lost item',
    'PRE-UNICRN' => 'Lost item',
    'RECAL-BILL' => 'Lost item',
    'RECAL-FEE' => 'Overdue recall',
    'RECOD-MBIL' => 'Lost item',
    'RECOD-MFEE' => 'Processing fee',
    'RECOD-MOD' => 'Lost item',
    'BADCHECK' => 'Privileges fee',
    'LOSTRECALL' => 'Lost item',
    'MISC' => 'Overdue item'
  }.freeze

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def sequence
    key&.split(':')&.last&.to_i
  end

  def patron_key
    fields['patron']['key']
  end

  def status
    fields.dig('block', 'key')
  end

  def nice_status
    FINE_STATUS[status] || status
  end

  def library
    fields['library']['key']
  end

  def bill_date
    Time.zone.parse(fields['billDate']) if fields['billDate']
  end

  def owed
    fields['owed']['amount'].to_d
  end

  def fee
    fields.dig('amount', 'amount')&.to_d
  end

  def bib?
    bib.present?
  end

  def to_partial_path
    'fines/fine'
  end

  private

  def fields
    record['fields']
  end
end
