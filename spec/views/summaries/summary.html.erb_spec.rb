# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'summaries/_summary' do
  let(:fines) { [instance_double(Symphony::Fine, owed: 3, status: 'A', sequence: '1')] }
  let(:patron) do
    instance_double(Symphony::Patron, key: 'abc-1234-def-56', barcode: '1', fines: fines, can_pay_fines?: true,
                                      requests: [], checkouts: [],remaining_checkouts: nil)
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron_or_group).and_return(patron)
      allow(view).to receive(:patron).and_return(patron)
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
      instance_double(Symphony::Patron, key: 'abc-1234-def-56', barcode: '1', fines: [], can_pay_fines?: true,
                                        requests: [], checkouts: [], remaining_checkouts: nil)
    end

    it 'does not show the shared computer payment alert' do
      render

      expect(rendered).not_to have_text('Shared computer users: Due to computer security risks, you should not use a shared computer to make a fine payment.') # rubocop:disable Layout/LineLength
    end
  end
end
