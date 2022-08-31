# frozen_string_literal: true

# Model for requests in Symphony
class Request
  # A sufficiently large time used to sort nil values last
  # TODO: Update before 2099
  END_OF_DAYS = Time.zone.parse('2099-01-01')

  attr_reader :record

  def initialize(record)
    @record = record
  end

  def to_partial_path
    return 'checkouts/cdl_checkout' if cdl_checkedout?

    'requests/request'
  end

  def key
    record['requestId']
  end

  def patron_key
    nil
  end

  def resource
    nil
  end

  def status
    record['status']
  end

  def ready_for_pickup?
    status == 'Open - Awaiting pickup' || cdl_next_up?
  end

  def queue_position
    record['queuePosition']
  end

  def queue_length
    '?'
  end

  def expiration_date
    Time.zone.parse(record['expirationDate']) if record['expirationDate']
  end

  def placed_date
    Time.zone.parse(record['requestDate']) if record['requestDate']
  end

  def fill_by_date
    Time.zone.parse(record['fillByDate']) if record['fillByDate']
  end

  def waitlist_position
    return 'Unknown' if queue_position.nil? && queue_length.nil?

    "#{queue_position} of #{queue_length}"
  end

  def active?
    status.start_with?('Open')
  end

  def item_call_key
    # holdings record id? we don't have it in the patron API response
    # but it is in the requests API response
    nil
  end

  ##
  # Expensive calculation of CDL waitlist
  def cdl_waitlist_position
    return 'Next up ' if cdl_next_up?

    catalog_info = CatalogInfo.find(barcode)
    cdl_queue_length = catalog_info.hold_records.count(&:cdl_checkedout?)
    "#{queue_position - cdl_queue_length} of #{queue_length - cdl_queue_length}"
  end

  def pickup_library
    return 'CDL' if cdl?

    record['pickupLocationId']
  end

  def placed_library
    nil
  end

  def library
    if from_borrow_direct?
      Settings.BORROW_DIRECT_CODE
    elsif from_ill?
      Settings.ILL_CODE
    elsif cdl?
      'CDL'
    else
      library_key
    end
  end

  def from_ill?
    (library_key == 'SUL') || from_borrow_direct? || from_ilb?
  end

  # rubocop:disable Metrics/MethodLength
  def sort_key(key)
    sort_key = case key
               when :library
                 [pickup_library, title, author, shelf_key]
               when :date
                 [*date_sort_key, title, author, shelf_key]
               when :title
                 [title, author, shelf_key]
               when :author
                 [author, title, shelf_key]
               when :call_number
                 [shelf_key]
               end

    sort_key.join('---')
  end
  # rubocop:enable Metrics/MethodLength

  def date_sort_key
    [
      (expiration_date || END_OF_DAYS).strftime('%FT%T'),
      (fill_by_date || END_OF_DAYS).strftime('%FT%T')
    ]
  end

  def circ_record
    return unless cdl? && cdl_circ_record_key

    @circ_record ||= begin
      record = Checkout.find(cdl_circ_record_key, cdl: true)
      return unless record.checkout_date == cdl_circ_record_checkout_date

      record
    end
  end

  def cdl?
    cdl[0] == 'CDL'
  end

  def cdl_druid
    cdl[1]
  end

  def cdl_circ_record_key
    cdl[2].presence
  end

  def cdl_circ_record_checkout_date
    return if cdl[3].blank?

    Time.zone.at(cdl[3].to_i)
  end

  def cdl_next_up?
    cdl[4] == 'NEXT_UP'
  end

  def cdl_checkedout?
    circ_record.present? if cdl[4] == 'ACTIVE'
  end

  def cdl_expiration_date
    return unless cdl_circ_record_checkout_date

    cdl_circ_record_checkout_date + 30.minutes
  end

  def cdl_loan_period
    return unless cdl?

    (item.dig('itemCategory3', 'key')&.scan(/^CDL-(\d+)H$/)&.flatten&.first&.to_i || 2).hours
  end

  def cdl
    comment.split(';')
  end

  def comment
    ''
  end

  # TODO: store an Item object in the request and fetch these record from it
  def title
    @record.dig('item', 'title')
  end

  def author
    @record.dig('item', 'author')
  end

  def shelf_key
    ''
  end

  def call_number
    ''
  end

  def catkey
    ''
  end

  private

  def library_key
    nil
  end

  def from_ilb?
    item_type&.starts_with? 'ILB'
  end

  def from_borrow_direct?
    item_type == 'BORROWDIR'
  end

  def item_type
    nil
  end
end
