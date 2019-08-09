# frozen_string_literal: true

# Common accessors into bib item data
module BibRecord
  def barcode
    item['barcode']
  end

  def catkey
    fields.dig('bib', 'key') || item.dig('bib', 'key')
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

  def resource
    fields.dig('item', 'resource')
  end

  def item_key
    fields.dig('item', 'key')
  end

  def home_location
    item.dig('homeLocation', 'key')
  end

  def current_location
    item.dig('currentLocation', 'key')
  end

  def lost?
    current_location == 'LOST-ASSUM'
  end

  private

  def item
    fields.dig('item', 'fields') || {}
  end

  def bib
    fields.dig('bib', 'fields') || fields.dig('item', 'fields', 'bib', 'fields') || {}
  end

  def call
    item.dig('call', 'fields') || {}
  end
end
