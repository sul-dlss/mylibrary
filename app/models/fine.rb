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

  def sequence
    key&.split(':')&.last
  end

  def patron_key
    fields['patron']['key']
  end

  def status
    fields.dig('block', 'key')
  end

  def nice_status
    Settings.FINE_STATUS[status] || status
  end

  def catkey
    bib && fields['item']['fields']['bib']['key']
  end

  def title
    bib && bib['title']
  end

  def author
    bib && bib['author']
  end

  def call_number
    call && call['dispCallNumber']
  end

  def shelf_key
    call && call['sortCallNumber']
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

  def bib
    fields['item'] && fields['item']['fields']['bib'] && fields['item']['fields']['bib']['fields']
  end

  def call
    fields['item'] && fields['item']['fields']['call'] && fields['item']['fields']['call']['fields']
  end
end
