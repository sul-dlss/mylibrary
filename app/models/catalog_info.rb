# frozen_string_literal: true

# Accessing item catalog information from the symphony response
class CatalogInfo
  def self.find(barcode)
    new(SymphonyClient.new.catalog_info(barcode))
  end

  def initialize(record = {})
    @record = record
  end

  def fields
    (@record || {})['fields'] || {}
  end

  def callkey
    fields.dig('call', 'key')
  end

  def hold_records
    Array.wrap(fields.dig('bib', 'fields', 'holdRecordList')&.map { |record| Request.new(record) }&.select do |record|
      callkey == record.item_call_key && record.active?
    end)
  end
end
