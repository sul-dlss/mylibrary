# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/_pay_all_button.html.erb' do
  subject(:output) { Capybara.string(rendered) }

  let(:patron) { instance_double(Patron, barcode: '1', fines: fines, can_pay_fines?: true) }
  let(:fines) { [instance_double(Fine, owed: 3, status: 'A', sequence: '1')] }

  before do
    controller.singleton_class.class_eval do
      protected

      def patron_or_group; end
      helper_method :patron_or_group
    end

    allow(view).to receive(:patron_or_group).and_return(patron)
  end

  it 'renders a button' do
    render

    expect(output).to have_css('a.btn', text: 'Pay $3.00 now')
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
