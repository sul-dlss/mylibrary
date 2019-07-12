# frozen_string_literal: true

# Model for policy data
class Policy
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

  def method_missing(method_name, *arguments, &block)
    if fields.key?(method_name.to_s)
      fields[method_name.to_s]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    fields.key?(method_name.to_s) || super
  end
end
