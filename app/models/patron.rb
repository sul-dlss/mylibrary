# frozen_string_literal: true

# Class to model Patron information
class Patron
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def email
    email_resource = fields['address1'].find do |address|
      address['fields']['code']['key'] == 'EMAIL'
    end
    email_resource && email_resource['fields']['data']
  end

  private

  def fields
    record['fields']
  end
end
