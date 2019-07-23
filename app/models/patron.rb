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

  def remaining_checkouts
    return unless  borrow_limit

    borrow_limit - checkouts.length
  end

  def group?
    member_list.any?
  end

  def member_list
    @member_list ||= begin
      members = fields.dig('groupSettings', 'fields', 'group', 'fields', 'memberList') || []
      members.map { |member| Patron.new(member) }.reject { |patron| patron.key == key || patron.sponsor? }
    end
  end

  def member_list_names
    @member_list_names ||= begin
      member_list.each_with_object({}) { |member, hash| hash[member.key] = member.first_name }
    end
  end

  def member_name(key)
    member_list_names.fetch(key, '').gsub(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/, '\2')
  end

  def proxy_borrower?
    fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'PROXY'
  end

  def proxy_borrower_name
    "Proxy #{first_name.gsub(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/, '\2')}" if proxy_borrower?
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
    @requests ||= fields['holdRecordList'].map { |request| Request.new(request) }
  end

  def group_checkouts
    @group_checkouts ||= member_list.flat_map(&:checkouts)
  end

  def group_fines
    @group_fines ||= member_list.flat_map(&:fines)
  end

  def group_requests
    @group_requests ||= member_list.flat_map(&:requests)
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
