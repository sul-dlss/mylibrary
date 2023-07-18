# frozen_string_literal: true

module Folio
  # ? FOLIO: Fine = "FeeFine" in Folio - consider renaming for clarity
  class Fine
    include Folio::FolioRecord

    attr_reader :record

    def initialize(record)
      @record = record
    end

    def key
      record['id']
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
      record.dig('feeFine', 'feeFineType')
    end

    def library
      record.dig('item', 'effectiveLocation', 'library', 'name')
    end

    def bill_date
      return if record['actions'].none?

      Time.zone.parse(record.dig('actions', 0, 'dateAction'))
    end

    def owed
      record['remaining']&.to_d
    end

    def fee
      record['amount']&.to_d
    end

    def bib?
      record['item'].present?
    end

    def author
      record.dig('item', 'instance', 'contributors')&.pluck('name')&.join(', ')
    end

    def title
      record.dig('item', 'instance', 'title')
    end

    def call_number
      record.dig('item', 'holdingsRecord', 'callNumber')
    end

    def to_partial_path
      'fines/fine'
    end
  end
end
