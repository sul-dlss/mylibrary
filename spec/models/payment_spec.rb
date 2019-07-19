# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment do
  context 'with ana item associated with payment record' do
    subject do
      described_class.new(record.with_indifferent_access)
    end

    let(:payment) { subject }
    let(:record) do
      {
        'billNumber' => '5',
        'billReasonDescription' => 'Overdue recall',
        'amount' => '21.00',
        'dateBilled' => '2013-11-25',
        'feePaymentInfo' => {
          'paymentDate' => '2013-12-23',
          'paymentAmount' => '21.00',
          'paymentTypeDescription' =>
            'Payment using credit or debit card via MyAccount'
        },
        'feeItemInfo' => {
          'itemLibraryID' => 'GREEN',
          'title' => 'California : a history'
        }
      }
    end

    it 'has a key' do
      expect(payment.key).to eq '5'
    end

    it 'has a bill description' do
      expect(payment.bill_description).to eq 'Overdue recall'
    end

    it 'has a bill amount' do
      expect(payment.bill_amount).to eq '21.00'
    end

    it 'has a bill date' do
      expect(payment.bill_date).to eq Time.strptime('2013-11-25', '%Y-%m-%d')
    end

    it 'has a payment amount' do
      expect(payment.payment_amount).to eq '21.00'
    end

    it 'has an item title' do
      expect(payment.item_title).to eq 'California : a history'
    end

    it 'has an item library' do
      expect(payment.item_library).to eq 'GREEN'
    end

    it 'has a payment date' do
      expect(payment.payment_date).to eq Time.strptime('2013-12-23', '%Y-%m-%d')
    end

    it 'has a resolution desctiption' do
      expect(payment.resolution).to eq 'Payment using credit or debit card via MyAccount'
    end

    it 'can tell if they paid their bill using a card' do
      expect(payment).to be_paid_fee
    end
  end

  context 'without item associated with payment' do
    subject do
      described_class.new(record.with_indifferent_access)
    end

    let(:payment) { subject }
    let(:record) do
      {
        'billNumber' => '6',
        'billReasonDescription' => 'Privileges fee',
        'amount' => '0.01',
        'dateBilled' => '2014-1-2',
        'feePaymentInfo' => {
          'paymentDate' => '2014-2-23',
          'paymentAmount' => '0.01',
          'paymentTypeDescription' =>
            'Fee cancelled'
        }
      }
    end

    it 'has a key' do
      expect(payment.key).to eq '6'
    end

    it 'has a bill description' do
      expect(payment.bill_description).to eq 'Privileges fee'
    end

    it 'has a bill amount' do
      expect(payment.bill_amount).to eq '0.01'
    end

    it 'has a bill date' do
      expect(payment.bill_date).to eq Time.strptime('2014-01-02', '%Y-%m-%d')
    end

    it 'has a payment amount' do
      expect(payment.payment_amount).to eq '0.01'
    end

    it 'has a placeholder for no item title' do
      expect(payment.item_title).to eq 'No item associated with this payment'
    end

    it 'does not have an item library' do
      expect(payment.item_library).to be nil
    end

    it 'has a payment date' do
      expect(payment.payment_date).to eq Time.strptime('2014-2-23', '%Y-%m-%d')
    end

    it 'has a resolution desctiption' do
      expect(payment.resolution).to eq 'Fee cancelled'
    end

    it 'can tell if they paid their bill using a card' do
      expect(payment).not_to be_paid_fee
    end
  end

  context 'when there is no payment description but there is a payment amount' do
    subject do
      described_class.new(record.with_indifferent_access)
    end

    let(:payment) { subject }
    let(:record) do
      {
        'feePaymentInfo' => {
          'paymentDate' => '2014-2-23',
          'paymentAmount' => '0.01'
        }
      }
    end

    it 'shows the resolution as Paid' do
      expect(payment.resolution).to eq 'Paid'
    end
  end

  context 'when there is no payment description and no payment amount' do
    subject do
      described_class.new(record.with_indifferent_access)
    end

    let(:payment) { subject }
    let(:record) do
      {
        'feePaymentInfo' => {
          'paymentDate' => '2014-2-23'
        }
      }
    end

    it 'shows the resolution as Paid' do
      expect(payment.resolution).to eq 'Unknown'
    end
  end
end
