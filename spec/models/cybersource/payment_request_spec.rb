# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cybersource::PaymentRequest do
  subject(:request_params) do
    described_class.new(user_id: '0340214b-5492-472d-b634-c5c115639465', amount: '100.00').sign!.to_h
  end

  before do
    allow(Cybersource::Security).to receive(:secret_key).and_return('very_secret')
  end

  it 'stores the amount of total charges' do
    expect(request_params[:amount]).to eq('100.00')
  end

  it 'stores the user id as the transaction reference number' do
    expect(request_params[:reference_number]).to eq('0340214b-5492-472d-b634-c5c115639465')
  end

  it 'signs the transaction parameters' do
    expect(request_params[:signature]).to be_present
  end
end
