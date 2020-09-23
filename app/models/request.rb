# frozen_string_literal: true

# Model for requests in Symphony
class Request
  include BibRecord

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
    record['key']
  end

  def patron_key
    fields['patron']['key']
  end

  def resource
    record['resource']
  end

  def status
    fields['status']
  end

  def ready_for_pickup?
    status == 'BEING_HELD' || cdl_next_up?
  end

  def queue_position
    fields['queuePosition']
  end

  def queue_length
    fields['queueLength']
  end

  def expiration_date
    Time.zone.parse(fields['expirationDate']) if fields['expirationDate']
  end

  def placed_date
    Time.zone.parse(fields['placedDate']) if fields['placedDate']
  end

  def fill_by_date
    Time.zone.parse(fields['fillByDate']) if fields['fillByDate']
  end

  def waitlist_position
    return 'Unknown' if queue_position.nil? && queue_length.nil?

    "#{queue_position} of #{queue_length}"
  end

  def pickup_library
    return 'CDL' if cdl?

    fields['pickupLibrary']['key']
  end

  def placed_library
    fields['placedLibrary']['key']
  end

  def library
    code = item&.dig('library', 'key')
    code ||= bib['callList']&.first&.dig('fields', 'library', 'key')
    return Settings.BORROW_DIRECT_CODE if from_borrow_direct?
    return 'CDL' if cdl?

    code
  end

  def from_borrow_direct?
    fields.dig('item', 'fields', 'library', 'key') == 'SUL'
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

  def cdl_checkedout?
    circ_record.present? && !cdl_next_up?
  end

  def cdl_circ_record_key
    cdl[2].presence
  end

  def cdl_druid
    cdl[1]
  end

  def cdl_next_up?
    cdl[4] == 'NEXT_UP'
  end

  def cdl_circ_record_checkout_date
    return if cdl[3].blank?

    Time.zone.at(cdl[3].to_i)
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
    fields['comment'].to_s
  end

  private

  def fields
    record['fields']
  end
end
