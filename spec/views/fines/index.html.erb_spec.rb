# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/index' do
  context 'with a Symphony Fine' do
    let(:fine) do
      instance_double(Symphony::Fine, owed: 3, status: 'A', sequence: '1', nice_status: 'Damaged',
                                      bib?: false, key: 'abc', bill_date: Date.new, fee: 5,
                                      library: 'Best Lib', barcode: '12345')
    end
    let(:fines) { [fine] }
    let(:checkouts) { [] }
    let(:patron) do
      instance_double(Symphony::Patron, barcode: '1', fines: fines, can_pay_fines?: true, requests: [],
                                        checkouts: checkouts, remaining_checkouts: nil, barred?: false,
                                        status: 'OK', group?: false)
    end

    before do
      assign(:fines, fines)
      assign(:checkouts, checkouts)
      allow(fine).to receive(:to_partial_path).and_return('fines/fine')
      without_partial_double_verification do
        allow(view).to receive_messages(patron_or_group: patron, patron: patron)
      end
    end

    context 'when the patron has fines' do
      it 'shows the shared computer payment alert' do
        render

        expect(rendered).to have_text('Shared computer users: Due to computer security risks, you should not use a shared computer to make a fine payment.') # rubocop:disable Layout/LineLength
      end
    end

    context 'when the patron has no fines' do
      let(:patron) do
        # create a patron with empty array for fines
        instance_double(Symphony::Patron, barcode: '1', fines: [], can_pay_fines?: true, requests: [], checkouts: [],
                                          remaining_checkouts: nil, barred?: false, status: 'OK', group?: false)
      end

      it 'does not show the shared computer payment alert' do
        render

        expect(rendered).not_to have_text('Shared computer users: Due to computer security risks, you should not use a shared computer to make a fine payment.') # rubocop:disable Layout/LineLength
      end
    end
  end

  context 'with a FOLIO Fine' do
    let(:fine) do
      instance_double(Folio::Account,
                      owed: 3,
                      status: 'A',
                      sequence: '1',
                      nice_status: 'Damaged',
                      bib?: true,
                      key: 'abc',
                      bill_date: Date.new,
                      fee: 5,
                      library:
                      'Best Lib',
                      barcode: '12345',
                      author: 'Author 1',
                      title: 'Title',
                      shelf_key: 'AB 1234',
                      call_number: 'AB 1234',
                      catkey: '12345')
    end
    let(:fines) { [fine] }
    let(:checkouts) do
      [Folio::Checkout.new(
        { 'id' => '31d15973-acb6-4a12-92c7-5e2d5f2470ed',
          'item' =>
           { 'title' =>
             'Mental growth during the first three years' },
          'overdue' => true,
          'details' =>
           { 'feesAndFines' => { 'amountRemainingToPay' => 10 } } }
      )]
    end
    let(:patron) do
      instance_double(Folio::Patron, barcode: '1', fines: fines, can_pay_fines?: true, requests: [],
                                     checkouts: checkouts, remaining_checkouts: nil, barred?: false,
                                     status: 'OK', group?: false)
    end

    before do
      assign(:fines, fines)
      assign(:checkouts, checkouts)
      allow(fine).to receive(:to_partial_path).and_return('fines/fine')
      without_partial_double_verification do
        allow(view).to receive_messages(patron_or_group: patron, patron: patron)
      end
    end

    it 'shows the fined item author' do
      render

      expect(rendered).to have_text('Author 1')
    end

    context 'when the patron has accruing fines' do
      it 'shows the accrued amount' do
        render

        expect(rendered).to have_text('Accruing: $10.00')
      end
    end
  end
end
