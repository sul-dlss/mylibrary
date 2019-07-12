# frozen_string_literal: true

# Model for requests in Symphony
class Request
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def status
    fields['status']
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
