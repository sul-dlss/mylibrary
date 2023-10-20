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

    # returns the equivalent Symphony location code
    def home_location
      Folio::LocationsMap.for(permanent_location_code)&.last
    end

    # returns the equivalent Symphony location code
    def current_location
      Folio::LocationsMap.for(item.dig('effectiveLocation', 'code'))&.last
    end

    private

    def item
      record.dig('item', 'item') || {}
    end

    # ? FOLIO: not sure the word 'bib' is accurate anymore here / maybe confusing
    def bib
      record['item']
    end

    # Fall back to the holding record's effective location.
    # We are no longer guaranteed an item-level permanent location.
    def permanent_location_code
      item.dig('permanentLocation', 'code') ||
        item.dig('holdingsRecord', 'effectiveLocation', 'code')
    end
  end
end
