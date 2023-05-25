# frozen_string_literal: true

module Folio
  # Class to model Patron information
  class Patron
    attr_reader :patron_info, :payment_in_process

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

    def initialize(patron_info, payment_in_process = {})
      @patron_info = patron_info
      @payment_in_process = payment_in_process
    end

    def user_info
      patron_info['user'] || {}
    end

    def key
      user_info['id']
    end

    def barcode
      user_info['barcode']
    end

    def university_id
      user_info['externalSystemId']
    end

    def status
      user_info['active'] ? 'OK' : 'Blocked'
    end

    def standing
      'OK'
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
      Time.zone.parse(user_info['expirationDate']) if user_info['expirationDate']
    end

    def email
      user_info.dig('personal', 'email')
    end

    def patron_type
      nil
    end

    def fee_borrower?
      patron_type == 'Fee borrower'
    end

    def first_name
      user_info.dig('personal', 'firstName')
    end

    def last_name
      user_info.dig('personal', 'lastName')
    end

    def display_name
      return proxy_borrower_name if proxy_borrower_name.present?

      "#{first_name} #{last_name}"
    end

    def borrow_limit
      nil
    end

    def remaining_checkouts
      return unless borrow_limit

      borrow_limit - checkouts.length
    end

    def proxy_borrower?
      false
    end

    def sponsor?
      false
    end

    def checkouts
      @checkouts ||= patron_info['loans'].map { |checkout| Checkout.new(checkout) }
    end

    def fines
      all_fines
      # all_fines.reject { |fine| payment_sequence.include?(fine.sequence) }
    end

    def all_fines
      # @all_fines ||= []
      @all_fines ||= patron_info['charges'].map { |fine| Fine.new(fine) }
    end

    ##
    # Creates a range of integers based of a payment sequence string
    def payment_sequence
      return Range.new(0, 0) unless payment_in_process[:billseq] && payment_in_process[:pending]

      Range.new(*payment_in_process[:billseq].split('-').map(&:to_i))
    end

    def requests
      @requests ||= folio_requests + borrow_direct_requests
    end

    def group
      @group ||= Folio::Group.new(user_info)
    end

    def group?
      group&.member_list&.any?
    end

    def group_checkouts
      return checkouts.select { |checkout| group_circuser_info_keys.include?(checkout.key) } if sponsor?

      checkouts
    end

    def group_circuser_info_keys
      @group_circuser_info_keys ||= SymphonyDbClient.new.group_circuser_info_keys(key)
    end

    def group_requests
      return requests.select { |request| group_holduser_info_keys.include?(request.key) } if sponsor?

      requests
    end

    def group_holduser_info_keys
      @group_holduser_info_keys ||= SymphonyDbClient.new.group_holduser_info_keys(key)
    end

    def group_fines
      return fines.select { |fine| group_billuser_info_keys.include?(fine.key) } if sponsor?

      fines
    end

    def group_billuser_info_keys
      @group_billuser_info_keys ||= SymphonyDbClient.new.group_billuser_info_keys(key)
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

    def folio_requests
      @patron_info['holds'].map { |request| Request.new(request) }
    end

    def affiliations
      []
    end

    def proxy_borrower_name
      return unless proxy_borrower? && first_name.match?(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/)

      first_name.gsub(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/, '\2')
    end
  end
end
