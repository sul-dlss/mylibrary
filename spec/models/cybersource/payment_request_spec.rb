# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cybersource::PaymentRequest do
  subject(:request_params) do
    described_class.new(user_id: '0340214b-5492-472d-b634-c5c115639465', amount: '100.00', fine_ids:).sign!.to_h
  end

  let(:fine_ids) do
    %w[4085f2b8-80f4-431d-ac3c-25cc2b62d4f6
       a4aedaea-1750-461e-b7bd-2c90ba6b95bc
       a27c153e-b339-4fcb-8abb-fe846e37ded5
       ab6dc99f-bb59-44d0-93e8-efe36f99c6e5]
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

  it 'includes compressed account ids in the complete route' do
    expect(request_params[:complete_route]).to eq('4085f2b:a4aedae:a27c153:ab6dc99')
  end
end
