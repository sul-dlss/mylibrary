# frozen_string_literal: true

# Model for the Fine page
class Fine
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def status
    fields['block']['key']
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

  def library
    fields['library']['key']
  end

  def bill_date
    Time.zone.parse(fields['billDate']) if fields['billDate']
  end

  def owed
    fields['owed']['amount'].to_d
  end

  def to_partial_path
    'fines/fine'
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
