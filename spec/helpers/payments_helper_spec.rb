# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsHelper do
  describe 'cybersource pay url' do
    before do
      controller.singleton_class.class_eval do
        protected

        def patron_or_group; end

        helper_method :patron_or_group
      end
    end

    let(:fines) do
      [
        instance_double(Fine, status: 'BAD-CHECK', sequence: '1', owed: 11),
        instance_double(Fine, status: 'OVERDUE', sequence: '2', owed: 12),
        instance_double(Fine, status: 'LOST', sequence: '3', owed: 13)
      ]
    end

    context 'when the payment is for an individual' do
      let(:patron) do
        instance_double(Patron, fines: fines, barcode: '1234567890')
      end

      before do
        allow(helper).to receive(:patron_or_group).and_return(patron)
      end

      it 'contructs a url to cybersource to initiate a payment' do
        expect(helper.cybersource_pay_url).to eq 'https://example.com/secureacceptance/payment_form.php?amount=36.00&billseq=1-3&group=&reason=BAD-CHECK%2COVERDUE%2CLOST&session_id=UNUSED&user=1234567890'
      end
    end

    context 'when the payment is for a group' do
      let(:group) do
        Group.new({}).tap do |group|
          allow(group).to receive(:fines).and_return(fines)
          allow(group).to receive(:barcode).and_return('1234567890')
        end
      end

      before do
        allow(helper).to receive(:patron_or_group).and_return(group)
      end

      it 'constructs a url with the parameter group=G' do
        expect(helper.cybersource_pay_url).to match('group=G')
      end
    end
  end
end
