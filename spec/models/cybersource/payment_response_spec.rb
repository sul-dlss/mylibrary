# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cybersource::PaymentResponse do
  subject(:cybersource_response) { described_class.new(params.permit!.to_h) }

  let(:signature) do
    Cybersource::Security.generate_signature(
      {
        req_amount: '100.00',
        req_reference_number: '0340214b-5492-472d-b634-c5c115639465'
      }
    )
  end
  let(:decision) { 'ACCEPT' }
  let(:params) do
    ActionController::Parameters.new(req_amount: '100.00',
                                     req_reference_number: '0340214b-5492-472d-b634-c5c115639465',
                                     signed_field_names: 'req_amount,req_reference_number',
                                     unsigned_field_names: '',
                                     signature:,
                                     decision:)
  end

  it 'parses the user id from the merchant defined data' do
    expect(cybersource_response.user_id).to eq('0340214b-5492-472d-b634-c5c115639465')
  end

  it 'parses the amount of total charges' do
    expect(cybersource_response.amount).to eq('100.00')
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
