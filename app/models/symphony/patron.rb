# frozen_string_literal: true
module Symphony
  # Class to model Patron information
  class Patron
    attr_reader :record, :payment_in_process

    CHARGE_LIMIT_THRESHOLD = 25_000

    PATRON_STANDING = {
      'BARRED' => 'Contact us',
      'COLLECTION' => 'Blocked',
      'BLOCKED' => 'Blocked',
      'DELINQUENT' => 'OK',
      'OK' => 'OK'
    }.freeze

    USER_PROFILE = {
      'MXFEE' => 'Fee borrower',
      'MXFEE-BUS' => 'Fee borrower',
      'MXFEE-LAW' => 'Fee borrower',
      'MXFEE-NO25' => 'Fee borrower'
    }.freeze

    def initialize(record, payment_in_process = {})
      @record = record
      @payment_in_process = payment_in_process
    end

    def key
      record['key']
    end

    def barcode
      record['fields']['barcode']
    end

    def university_id
      record.dig('fields', 'alternateID')
    end

    def status
      if expired?
        'Expired'
      elsif proxy_borrower?
        # proxy borrowers inherit from the group
        group.status
      else
        PATRON_STANDING.fetch(standing, '')
      end
    end

    def standing
      fields.dig('standing', 'key')
    end

    def barred?
      # proxy borrowers inherit from the group
      if proxy_borrower?
        group.standing == 'BARRED'
      else
        standing == 'BARRED'
      end
    end

    def blocked?
      # proxy borrowers inherit from the group
      if proxy_borrower?
        group.standing == 'BLOCKED'
      else
        standing == 'BLOCKED'
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
      if user_profile.present?
        user_profile
      elsif proxy_borrower?
        'Research group proxy'
      end
    end

    def fee_borrower?
      patron_type == 'Fee borrower'
    end

    def first_name
      fields['firstName']
    end

    def last_name
      fields['lastName']
    end

    def display_name
      return proxy_borrower_name if proxy_borrower_name.present?

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

    def proxy_borrower?
      fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'PROXY'
    end

    def sponsor?
      fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'SPONSOR'
    end

    def checkouts
      @checkouts ||= fields['circRecordList'].map { |checkout| Symphony::Checkout.new(checkout) }
    end

    def fines
      all_fines.reject { |fine| payment_sequence.include?(fine.sequence) }
    end

    def all_fines
      @all_fines ||= fields['blockList'].map { |fine| Symphony::Fine.new(fine) }
    end

    ##
    # Creates a range of integers based of a payment sequence string
    def payment_sequence
      return Range.new(0, 0) unless payment_in_process[:billseq] && payment_in_process[:pending]

      Range.new(*payment_in_process[:billseq].split('-').map(&:to_i))
    end

    def requests
      @requests ||= symphony_requests + borrow_direct_requests
    end

    def group
      @group ||= Group.new(record)
    end

    def group?
      group.member_list.any?
    end

    def group_checkouts
      return checkouts.select { |checkout| group_circrecord_keys.include?(checkout.key) } if sponsor?

      checkouts
    end

    def group_circrecord_keys
      @group_circrecord_keys ||= SymphonyDbClient.new.group_circrecord_keys(key)
    end

    def group_requests
      return requests.select { |request| group_holdrecord_keys.include?(request.key) } if sponsor?

      requests
    end

    def group_holdrecord_keys
      @group_holdrecord_keys ||= SymphonyDbClient.new.group_holdrecord_keys(key)
    end

    def group_fines
      return fines.select { |fine| group_billrecord_keys.include?(fine.key) } if sponsor?

      fines
    end

    def group_billrecord_keys
      @group_billrecord_keys ||= SymphonyDbClient.new.group_billrecord_keys(key)
    end

    def to_partial_path
      return 'patron/expired' if expired?
      return 'patron/fee_borrower' if fee_borrower?

      'patron/patron'
    end

    def can_renew?
      return false if barred? || blocked? || expired?

      true
    end

    def can_modify_requests?
      return false if barred? || blocked? || expired?

      true
    end

    def can_pay_fines?
      return false if barred?

      true
    end

    private

    def academic_staff_or_fellow?
      return unless profile_key == 'CNAC'

      allowed_affiliations = ['affiliate:fellow', 'staff:academic', 'staff:otherteaching']

      (affiliations & allowed_affiliations).any?
    end

    def borrow_direct_requests
      return [] if proxy_borrower? # Proxies can't submit borrow direct requests, so don't check.

      if Settings.borrow_direct_reshare.enabled
        BorrowDirectReshareRequests.new(university_id).requests
      else
        BorrowDirectRequests.new(barcode).requests
      end
    end

    def symphony_requests
      fields['holdRecordList'].map { |request| Request.new(request) }
    end

    def fields
      record['fields']
    end

    def profile
      fields['profile']['fields'] || {}
    end

    def profile_key
      fields.dig('profile', 'key')
    end

    def user_profile
      USER_PROFILE.fetch(profile_key, '')
    end

    def affiliations
      fields['customInformation'].select { |ci| ci.dig('fields', 'code', 'key') =~ /AFFIL\d/ }.map do |info|
        info.dig('fields', 'data')
      end.compact
    end

    def proxy_borrower_name
      return unless proxy_borrower? && first_name.match?(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/)

      first_name.gsub(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/, '\2')
    end
  end
end
