# frozen_string_literal: true

module Folio
  # ? FOLIO: Fine = "FeeFine" in Folio - consider renaming for clarity
  class Fine
    include Folio::FolioRecord

    attr_reader :record

    # ? FOLIO: need to recalibrate these statuses
    FINE_STATUS = {}.freeze

    def initialize(record)
      @record = record
    end

    def key
      record['feeFineId']
    end

    def sequence
      # ? FOLIO
      nil
    end

    def patron_key
      record['userId']
    end

    def status
      record.dig('paymentStatus', 'name')
    end

    def nice_status
      record['feeFineType']
    end

    # returns the equivalent Symphony library code
    def library
      Folio::LocationsMap.for(record.dig('item', 'item', 'effectiveLocation', 'code'))&.first
    end

    def bill_date
      if record['dateCreated'] || record.dig(
        'metadata', 'createdDate'
      )
        Time.zone.parse(record['dateCreated'] || record.dig('metadata',
                                                            'createdDate'))
      end
    end

    def owed
      record['remaining']&.to_d || fee
    end

    def fee
      record['amount']&.to_d
    end

    def bib?
      record['item'].present?
    end

    def to_partial_path
      'fines/fine'
    end
  end
end
