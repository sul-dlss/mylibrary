# frozen_string_literal: true

module Cybersource
  # Request sent to Cybersource to initiate an external checkout
  # See the PDF linked in the README for more information on the fields
  class PaymentRequest
    include Enumerable

    attr_reader :user, :amount, :session_id, :signature, :signed_date_time

    # Set of fields we use to generate the signature and that Cybersource verifies
    REQUEST_SIGNED_FIELDS = %i[access_key profile_id transaction_uuid signed_date_time
                               locale transaction_type reference_number amount currency unsigned_field_names
                               signed_field_names merchant_defined_data1].freeze

    def initialize(user:, amount:, session_id:)
      @user = user
      @amount = amount
      @session_id = session_id
      @signed_fields = REQUEST_SIGNED_FIELDS
      @unsigned_fields = []
      @signed_date_time, @signature = nil
    end

    # Hash form including all data and signature
    def to_h
      signed_data.merge(unsigned_data).merge(signature: @signature)
    end

    # Support iterating keys and values for rendering as hidden form fields
    def each(&block)
      to_h.each(&block)
    end

    # Generate a security signature for the data and add a timestamp
    def sign!
      @signed_date_time = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      @signature = Cybersource::Security.generate_signature(signed_data)

      self
    end

    def validate!
      Cybersource::Security.validate_signature!(@signature, signed_data)

      self
    end

    def signed?
      @signature.present?
    end

    def valid?
      Cybersource::Security.valid_signature?(@signature, signed_data)
    end

    private

    # Comma-separated parameter version of signed_fields
    def signed_field_names
      @signed_fields.join(',')
    end

    # Comma-separated parameter version of unsigned_fields
    def unsigned_field_names
      @unsigned_fields.join(',')
    end

    # Hash of signed fields and their values
    def signed_data
      @signed_data ||= @signed_fields.index_with { |field| send(field) }
    end

    # Hash of unsigned fields and their values
    def unsigned_data
      @unsigned_data ||= @unsigned_fields.index_with { |field| send(field) }
    end

    # Each transaction must have a unique ID
    def transaction_uuid
      @transaction_uuid ||= SecureRandom.uuid
    end

    # Used to check if the user has a payment pending by comparing to a cookie
    def reference_number
      @session_id
    end

    # Passed back to us by Cybersource and used to look up the user in the ILS
    def merchant_defined_data1
      @user
    end

    # Matches us with configuration on the Cybersource side; differs for dev/test/prod
    def access_key
      Settings.cybersource.access_key
    end

    # Identifies us as a "merchant" to Cybersource; one value for SUL as a whole
    def profile_id
      Settings.cybersource.profile_id
    end

    def transaction_type
      'sale'
    end

    def locale
      'en'
    end

    def currency
      'USD'
    end
  end
end
