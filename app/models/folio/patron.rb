# frozen_string_literal: true

module Folio
  # Class to model Patron information
  class Patron
    attr_reader :patron_info

    CHARGE_LIMIT_THRESHOLD = 25_000

    def initialize(patron_info)
      @patron_info = patron_info
    end

    # pass a FOLIO user uuid and get back a Patron object
    def self.find(key)
      patron_info = FolioClient.new.patron_info(key)
      new(patron_info)
    end

    def user_info
      patron_info['user'] || {}
    end

    # The patron key can be in one of two places; either on the user data (if it's from the FOLIO API)
    # or at the top level (if it's from the GraphQL API)
    def key
      patron_info['id'] || user_info['id']
    end

    def barcode
      user_info['barcode']
    end

    def university_id
      user_info['externalSystemId']
    end

    def status
      standing
    end

    def standing
      if blocked?
        'Blocked'
      elsif barred?
        'Contact us'
      elsif expired?
        'Expired'
      else
        'OK'
      end
    end

    def barred?
      user_info['manualBlocks'].any?
    end

    def blocked?
      user_info['blocks'].any?
    end

    # From https://docs.folio.org/docs/users/: Inactive status indicates that the expiration date
    # on the user’s record has passed and the user is no longer affiliated, employed, or enrolled.
    # There are cases where a user record is inactive/expired and expirationDate is nil.
    def expired?
      !user_info['active']
    end

    def expired_date
      Time.zone.parse(user_info['expirationDate']) if user_info['expirationDate']
    end

    def email
      user_info.dig('personal', 'email')
    end

    def patron_type
      # FOLIO's patronGroup refers to the patron type, e.g. Undergraduate, Graduate, Faculty, etc.
      # this type of group is unrelated to our proxy/sponsor "research groups" in the model Folio::Group
      patron_type = user_info.dig('patronGroup', 'desc')

      return 'Fee borrower' if patron_type&.match?(/Fee borrower/i)

      # suppress the display of any other patron groups
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
      "#{first_name} #{last_name}"
    end

    def borrow_limit
      borrow_limit = user_info.dig('patronGroup', 'limits')&.find do |limit|
        limit.dig('condition', 'name') == 'Maximum number of items charged out'
      end
      borrow_limit&.dig('value')
    end

    def remaining_checkouts
      return unless borrow_limit

      borrow_limit - checkouts.length
    end

    def all_accounts
      @all_accounts ||= patron_info['accounts'].map { |account| Account.new(account) }
    end

    def fines
      all_accounts.reject(&:closed?)
    end

    def payments
      all_accounts.select(&:closed?)
    end

    # TODO: delete after FOLIO launch. All group fines are now affiliated with a single Sponsor patron.
    def group_fines
      []
    end

    # TODO: delete after FOLIO launch. All group payments are now affiliated with a single Sponsor patron.
    def group_payments
      []
    end

    def proxy_borrower?
      user_info['proxiesFor']&.any?
    end

    def sponsor?
      user_info['proxiesOf']&.any?
    end

    def group
      @group ||= Folio::Group.new(patron_info)
    end

    def group?
      group&.member_list&.any?
    end

    def all_checkouts
      @all_checkouts ||= patron_info['loans']&.map { |checkout| Checkout.new(checkout, patron_type_id) }
    end

    # Self checkouts
    def checkouts
      all_checkouts.reject(&:proxy_checkout?) || []
    end

    # Checkouts from the proxy group
    def group_checkouts
      all_checkouts.select(&:proxy_checkout?)
    end

    # Self requests: Combines data from FOLIO, borrow direct, and ILLIAD
    def requests
      @requests ||= folio_requests.reject(&:proxy_request?) + borrow_direct_requests + illiad_requests
    end

    # Requests from the proxy group
    def group_requests
      folio_requests.select(&:proxy_request?) if sponsor?
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

    # Generate a PIN reset token for the patron
    def pin_reset_token
      crypt.encrypt_and_sign(key, expires_in: 20.minutes)
    end

    private

    def academic_staff_or_fellow?
      return false unless profile_key == 'CNAC'

      allowed_affiliations = ['affiliate:fellow', 'staff:academic', 'staff:otherteaching']

      affiliations.intersect?(allowed_affiliations)
    end

    def borrow_direct_requests
      return [] if proxy_borrower? # Proxies can't submit borrow direct requests, so don't check.

      if Settings.borrow_direct_reshare.enabled
        BorrowDirectReshareRequests.new(university_id).requests
      else
        BorrowDirectRequests.new(barcode).requests
      end
    end

    # this is all requests including self and group/proxy
    def folio_requests
      @patron_info['holds'].map { |request| Request.new(request) }
    end

    def affiliations
      []
    end

    # ILLIAD requests are retrieved separately
    def illiad_requests
      return [] unless user_info['username']

      IlliadRequests.new(user_info['username']).requests
    end

    # Encryptor/decryptor for the token used in the PIN reset process
    def crypt
      @crypt ||= begin
        keygen = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
        key = keygen.generate_key('patron pin reset token', ActiveSupport::MessageEncryptor.key_len)
        ActiveSupport::MessageEncryptor.new(key)
      end
    end

    def patron_type_id
      # FOLIO's patronGroup refers to the patron type, e.g. Undergraduate, Graduate, Faculty, etc.
      # this type of group is unrelated to our proxy/sponsor "research groups" in the model Folio::Group
      user_info['patronGroupId']
    end
  end
end
