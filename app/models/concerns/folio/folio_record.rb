# frozen_string_literal: true

module Folio
  # Common accessors into record data
  module FolioRecord
    def catkey
      item.dig('instance', 'hrid')
    end

    def title
      bib['title']
    end

    def author
      bib['author']
    end

    def call_number
      item.dig('effectiveCallNumberComponents', 'callNumber')
    end

    def shelf_key
      item['effectiveShelvingOrder']
    end

    def barcode
      item['barcode']
    end

    def resource
      # ? FOLIO: This was required for Symphony renew_item requests.
      #     Setting this to the instanceId for now.
      bib['instanceId']
    end

    def item_key
      bib['itemId']
    end

    def home_location
      item.dig('permanentLocation', 'name')
    end

    def current_location
      item.dig('effectiveLocation', 'name')
    end

    def lost?
      current_location == 'LOST-ASSUM'
    end

    private

    def item
      record.dig('item', 'item') || {}
    end

    # ? FOLIO: not sure the word 'bib' is accurate anymore here / maybe confusing
    def bib
      record['item']
    end
  end
end
