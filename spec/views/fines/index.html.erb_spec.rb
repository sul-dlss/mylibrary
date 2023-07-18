# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/index' do
  let(:fine) do
    instance_double(Symphony::Fine, owed: 3, status: 'A', sequence: '1', nice_status: 'Damaged',
                                    bib?: false, key: 'abc', bill_date: Date.new, fee: 5,
                                    library: 'Best Lib', barcode: '12345')
  end
  let(:fines) { [fine] }
  let(:checkouts) { [] }
  let(:patron) do
    instance_double(Symphony::Patron, key: 'abc-1234-def-56', barcode: '1', fines: fines, can_pay_fines?: true,
                                      requests: [], checkouts: checkouts, remaining_checkouts: nil,
                                      barred?: false, status: 'OK', group?: false)
  end

  before do
    assign(:fines, fines)
    assign(:checkouts, checkouts)
    without_partial_double_verification do
      allow(view).to receive(:patron_or_group).and_return(patron)
      allow(view).to receive(:patron).and_return(patron)
      allow(fine).to receive(:to_partial_path).and_return('fines/fine')
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
