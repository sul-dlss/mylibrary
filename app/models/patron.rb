# frozen_string_literal: true

# Class to model Patron information
class Patron
  attr_reader :record

  PATRON_STANDING = {
    'COLLECTION' => 'Blocked',
    'BARRED' => 'Blocked',
    'BLOCKED' => 'Blocked',
    'OK' => 'OK',
    'DELINQUENT' => 'OK'
  }.freeze

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def first_name
    fields['firstName']
  end

  def last_name
    fields['lastName']
  end

  def status
    if expired?
      'Expired'
    else
      PATRON_STANDING.fetch(fields['standing']['key'], '')
    end
  end

  def expired?
    expired_date = fields['privilegeExpiresDate']
    expired_date.present? ? Time.zone.now.strftime('%Y-%m-%d') >= expired_date : false
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
