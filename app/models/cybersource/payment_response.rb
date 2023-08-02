# frozen_string_literal: true

module Cybersource
  # Response sent back by Cybersource after the external checkout is complete
  class PaymentResponse
    class PaymentFailed < StandardError; end

    def initialize(fields)
      @fields = fields
      @signed_fields = fields['signed_field_names'].split(',')
      @unsigned_fields = fields['unsigned_field_names'].split(',')
    end

    def to_h
      @fields
    end

    # If the payment was successful, Cybersource will send us back a decision of 'ACCEPT'
    def payment_success?
      @fields['decision'] == 'ACCEPT'
    end

    # Raise an error if the payment failed or if the signature is invalid
    def validate!
      Cybersource::Security.validate_signature!(@fields['signature'], signed_data)
      raise PaymentFailed unless payment_success?

      self
    end

    def valid?
      Cybersource::Security.valid_signature?(@fields['signature'], signed_data)
    end

    # Hash of signed fields and their values
    def signed_data
      @signed_data = @signed_fields.index_with { |field| @fields[field] }
    end

    def user
      @fields['req_merchant_defined_data1']
    end

    def amount
      @fields['req_amount']
    end

    def session_id
      @fields['req_reference_number']
    end
  end
end
