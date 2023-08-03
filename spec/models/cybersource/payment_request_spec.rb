# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cybersource::PaymentRequest do
  subject(:request_params) do
    described_class.new(user: '1234567890', amount: '100.00', session_id: '3672f43945ec20cf2966525aeb7691e4').sign!.to_h
  end

  before do
    allow(Cybersource::Security).to receive(:secret_key).and_return('very_secret')
  end

  it 'stores the user barcode as merchant defined data' do
    expect(request_params[:merchant_defined_data1]).to eq('1234567890')
  end

  it 'stores the amount of total charges' do
    expect(request_params[:amount]).to eq('100.00')
  end

  it 'stores the session id as the transaction reference number' do
    expect(request_params[:reference_number]).to eq('3672f43945ec20cf2966525aeb7691e4')
  end

  it 'signs the transaction parameters' do
    expect(request_params[:signature]).to be_present
  end
end
