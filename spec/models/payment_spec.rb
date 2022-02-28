# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment do
  subject(:payment) { described_class.new(record.with_indifferent_access) }

  let(:record) do
    {
      'billNumber' => '5',
      'billReasonDescription' => 'Overdue recall',
      'billReasonID' => 'OVERDUE',
      'amount' => '21.00',
      'dateBilled' => '2013-11-25',
      'feePaymentInfo' => {
        'paymentDate' => '2013-12-23',
        'paymentAmount' => '21.00',
        'paymentTypeID' => 'CREDITCARD'
      },
      'feeItemInfo' => {
        'itemLibraryID' => 'GREEN',
        'title' => 'California : a history'
      }
    }
  end

  context 'with an item associated with payment record' do
    it 'has a key' do
      expect(payment.key).to eq '5'
    end

    it 'has a bill description' do
      expect(payment.bill_description).to eq 'Overdue recall'
    end

    it 'has a translated bill description' do
      expect(payment.nice_bill_description).to eq 'Overdue item'
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

    it 'can tell if they paid their bill using a card' do
      expect(payment).to be_paid_fee
    end
  end

  context 'when payment resolution is a paid type' do
    it 'has a resolution description' do
      expect(payment.resolution).to eq 'Paid by credit card'
    end
  end

  context 'when payment resolution is forgiven' do
    let(:record) do
      {
        'billNumber' => '5',
        'billReasonDescription' => 'Overdue recall',
        'amount' => '21.00',
        'dateBilled' => '2013-11-25',
        'feePaymentInfo' => {
          'paymentDate' => '2013-12-23',
          'paymentAmount' => '21.00',
          'paymentTypeID' => 'FORGIVEN'
        }
      }
    end

    it 'has a resolution description' do
      expect(payment.resolution).to eq 'Forgiven'
    end
  end

  context 'when payment resolution is unknown' do
    let(:record) do
      {
        'billNumber' => '5',
        'billReasonDescription' => 'Overdue recall',
        'amount' => '21.00',
        'dateBilled' => '2013-11-25',
        'feePaymentInfo' => {
          'paymentDate' => '2013-12-23',
          'paymentAmount' => '21.00',
          'paymentTypeID' => 'GROMET',
          'paymentTypeDescription' => nil
        }
      }
    end

    it 'has a resolution description' do
      expect(payment.resolution).to eq 'Unknown'
    end
  end

  context 'with multiple payments' do
    let(:record) do
      {
        'billNumber' => '5',
        'billReasonDescription' => 'Overdue recall',
        'amount' => '21.00',
        'dateBilled' => '2013-11-25',
        'feePaymentInfo' => [
          {
            'paymentDate' => '2013-12-23',
            'paymentAmount' => '21.00',
            'paymentTypeID' => 'CREDITCARD',
            'paymentTypeDescription' =>
              'Payment using credit or debit card via MyAccount'
          },
          {
            'paymentDate' => '2018-11-03',
            'paymentAmount' => '1.00',
            'paymentTypeID' => 'CREDITCARD'
          }
        ],
        'feeItemInfo' => {
          'itemLibraryID' => 'GREEN',
          'title' => 'California : a history'
        }
      }
    end

    it 'picks the first one' do
      expect(payment.payment_amount).to eq '21.00'
    end
  end

  context 'without item associated with payment' do
    let(:record) do
      {
        'billNumber' => '6',
        'billReasonDescription' => 'Privileges fee',
        'amount' => '0.01',
        'dateBilled' => '2014-1-2',
        'feePaymentInfo' => {
          'paymentDate' => '2014-2-23',
          'paymentAmount' => '0.01',
          'paymentTypeID' =>
            'CANCEL'
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
      expect(payment.item_library).to be_nil
    end

    it 'has a payment date' do
      expect(payment.payment_date).to eq Time.strptime('2014-2-23', '%Y-%m-%d')
    end

    it 'has a resolution description' do
      expect(payment.resolution).to eq 'Removed'
    end

    it 'can tell if they paid their bill using a card' do
      expect(payment).not_to be_paid_fee
    end
  end

  context 'when there is no payment description and no payment amount' do
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

  describe '#sort_key' do
    def payment_with_date(bill_number, date)
      described_class.new(record.merge(
        'billNumber' => bill_number,
        'feePaymentInfo' => { 'paymentDate' => date }
      ).with_indifferent_access)
    end

    let(:payments) do
      [
        payment_with_date('1', nil),
        payment_with_date('2', '2017-2-23'),
        payment_with_date('3', '2014-2-23'),
        payment_with_date('4', '2015-2-23')
      ]
    end

    it 'sorts requests by payment date (inverted), with nil values last' do
      sorted_payments = payments.sort_by { |p| p.sort_key(:payment_date) }

      expect(sorted_payments.map(&:key)).to eq %w[1 2 4 3]
    end
  end
end
