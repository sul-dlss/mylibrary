# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'summaries/_summary' do
  let(:fines) { [instance_double(Folio::Account, owed: 3)] }
  let(:patron) do
    instance_double(Folio::Patron, key: '513a9054-5897-11ee-8c99-0242ac120002', fines:, can_pay_fines?: true,
                                   requests: [], checkouts: [], remaining_checkouts: nil)
  end

  before do
    without_partial_double_verification do
      allow(view).to receive_messages(patron_or_group: patron, patron:)
    end
  end

  context 'when the patron has fines' do
    it 'shows the shared computer payment alert' do
      render

      expect(rendered).to have_text('Shared computer users: Due to computer security risks, you should not use a shared computer to make a fine payment.') # rubocop:disable Layout/LineLength
    end
  end

  context 'when the patron has no fines' do
    let(:fines) { [] }

    it 'does not show the shared computer payment alert' do
      render

      expect(rendered).not_to have_text('Shared computer users: Due to computer security risks, you should not use a shared computer to make a fine payment.') # rubocop:disable Layout/LineLength
    end
  end
end
