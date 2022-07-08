# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/_pay_all_button' do
  subject(:output) { Capybara.string(rendered) }

  let(:patron) { instance_double(Patron, barcode: '1', fines: fines, can_pay_fines?: true) }
  let(:fines) { [instance_double(Fine, owed: 3, status: 'A', sequence: '1')] }

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
