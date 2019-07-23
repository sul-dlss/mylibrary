# frozen_string_literal: true

# Model for requests in Symphony
class Request
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def to_partial_path
    'requests/request'
  end

  def key
    record['key']
  end

  def patron_key
    fields['patron']['key']
  end

  def status
    fields['status']
  end

  def ready_for_pickup?
    status == 'BEING_HELD'
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
    "#{queue_position} of #{queue_length}"
  end

  def pickup_library
    fields['pickupLibrary']['key']
  end

  def placed_library
    fields['placedLibrary']['key']
  end

  private

  def fields
    record['fields']
  end

  def bib
    fields['item']['fields']['bib']['fields']
  end

  def call
    fields['item']['fields']['call']['fields']
  end
end
