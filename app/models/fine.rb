# frozen_string_literal: true

# ? FOLIO: Fine = "FeeFine" in Folio - consider renaming for clarity
class Fine
  include FolioRecord

  attr_reader :record

  # ? FOLIO: need to recalibrate these statuses
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
    # ? FOLIO
    'string'
  end

  def sequence
    # ? FOLIO
    key&.split(':')&.last&.to_i
  end

  def patron_key
    nil
    # ? FOLIO: don't think we need this as we now get it in the parent query
  end

  def status
    # ? FOLIO: is this the right field?
    record['state']
  end

  def nice_status
    FINE_STATUS[status] || status
  end

  def library
    # ? FOLIO: is this the right field? See bib_record
    home_location
  end

  def bill_date
    # ? FOLIO: is this the right field?
    Time.zone.parse(record['accrualDate']) if record['accrualDate']
  end

  def owed
    # ? FOLIO: is this the right field?
    record.dig('chargeAmount', 'amount')&.to_d
  end

  def fee
    # ? FOLIO: is this the right field?
    record.dig('chargeAmount', 'amount')&.to_d
  end

  def bib?
    # ? FOLIO: do we need this? See bib_record
    bib.present?
  end

  def to_partial_path
    'fines/fine'
  end
end
