class Item
  include BibRecord

  attr_reader :record

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  private

  def fields
    record['fields']
  end

  def item
    fields
  end
end
