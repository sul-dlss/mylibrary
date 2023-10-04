# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/_pay_all_button' do
  subject(:output) { Capybara.string(rendered) }

  let(:patron) do
    instance_double(Folio::Patron, key: '513a9054-5897-11ee-8c99-0242ac120002', fines: fines, can_pay_fines?: true)
  end
  let(:fines) { [instance_double(Folio::Account, owed: 3)] }

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron_or_group).and_return(patron)
    end
  end

  it 'renders a button' do
    render

    expect(output).to have_button 'Pay $3.00 now'
  end

  context 'when the patron is e.g. blocked and unable to renew material' do
    before do
      allow(patron).to receive(:can_pay_fines?).and_return(false)
    end

    it 'renders a disabled button' do
      render

      button = output.find('button', text: 'Payments blocked')
      expect(button).to be_disabled
    end
  end
end
