# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cybersource::PaymentResponse do
  subject(:cybersource_response) { described_class.new(params.permit!.to_h) }

  let(:signature) do
    Cybersource::Security.generate_signature(
      {
        req_merchant_defined_data1: '1234567890',
        req_amount: '100.00',
        req_reference_number: '3672f43945ec20cf2966525aeb7691e4'
      }
    )
  end
  let(:decision) { 'ACCEPT' }
  let(:params) do
    ActionController::Parameters.new(req_merchant_defined_data1: '1234567890',
                                     req_amount: '100.00',
                                     req_reference_number: '3672f43945ec20cf2966525aeb7691e4',
                                     signed_field_names: 'req_merchant_defined_data1,req_amount,req_reference_number',
                                     unsigned_field_names: '',
                                     signature: signature,
                                     decision: decision)
  end

  it 'parses the user barcode from the merchant defined data' do
    expect(cybersource_response.user).to eq('1234567890')
  end

  it 'parses the amount of total charges' do
    expect(cybersource_response.amount).to eq('100.00')
  end

  it 'parses the session id from the transaction reference number' do
    expect(cybersource_response.session_id).to eq('3672f43945ec20cf2966525aeb7691e4')
  end

  it 'validates that the transaction is signed and accepted' do
    expect { cybersource_response.validate! }.not_to raise_error
  end

  context 'when the signature is invalid' do
    let(:signature) { 'badsignature123' }

    it 'raises an error' do
      expect { cybersource_response.validate! }.to raise_error(Cybersource::Security::InvalidSignature)
    end
  end

  context 'when the payment failed' do
    let(:decision) { 'REJECT' }

    it 'raises an error' do
      expect { cybersource_response.validate! }.to raise_error(Cybersource::PaymentResponse::PaymentFailed)
    end
  end
end
