# frozen_string_literal: true

# Class to model Patron information
class Patron
  attr_reader :record

  CHARGE_LIMIT_THRESHOLD = 25_000

  PATRON_STANDING = {
    'COLLECTION' => 'Blocked',
    'BARRED' => 'Blocked',
    'BLOCKED' => 'Blocked',
    'OK' => 'OK',
    'DELINQUENT' => 'OK'
  }.freeze

  USER_PROFILE = {
    'MXFEE' => 'Fee borrower',
    'MXFEE-BUS' => 'Fee borrower',
    'MXFEE-LAW' => 'Fee borrower',
    'MXFEE-NO25' => 'Fee borrower'
  }.freeze

  def initialize(record)
    @record = record
  end

  def key
    record['key']
  end

  def status
    if expired?
      'Expired'
    else
      PATRON_STANDING.fetch(fields['standing']['key'], '')
    end
  end

  def expired?
    return false unless expired_date

    expired_date.past?
  end

  def expired_date
    Time.zone.parse(fields['privilegeExpiresDate']) if fields['privilegeExpiresDate']
  end

  def email
    email_resource = fields['address1'].find do |address|
      address['fields']['code']['key'] == 'EMAIL'
    end
    email_resource && email_resource['fields']['data']
  end

  def patron_type
    user_profile
  end

  def first_name
    fields['firstName']
  end

  def last_name
    fields['lastName']
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def borrow_limit
    return unless profile['chargeLimit']
    return if profile['chargeLimit'].to_i >= CHARGE_LIMIT_THRESHOLD

    profile['chargeLimit'].to_i
  end

  def proxy_borrower?
    fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'PROXY'
  end

  def sponsor?
    fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'SPONSOR'
  end

  def checkouts
    @checkouts ||= fields['circRecordList'].map { |checkout| Checkout.new(checkout) }
  end

  def fines
    @fines ||= fields['blockList'].map { |fine| Fine.new(fine) }
  end

  def requests
    @requests ||= if fields['holdRecordList'].nil?
                    []
                  else
                    fields['holdRecordList'].map { |request| Request.new(request) }
                  end
  end

  private

  def fields
    record['fields']
  end

  def profile
    fields['profile']['fields'] || {}
  end

  def user_profile
    USER_PROFILE.fetch(fields['profile']['key'], '')
  end
end
