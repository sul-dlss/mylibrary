# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'checkouts/_renew_all_button' do
  subject(:output) { Capybara.string(rendered) }

  let(:patron) { instance_double(Symphony::Patron, checkouts:, can_renew?: true) }
  let(:checkouts) { [instance_double(Symphony::Checkout, renewable?: true)] }

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron_or_group).and_return(patron)
    end
  end

  it 'renders a button' do
    render

    expect(output).to have_link 'Renew 1 eligible item'
  end

  context 'when the patron is e.g. blocked and unable to renew material' do
    before do
      allow(patron).to receive(:can_renew?).and_return(false)
    end

    it 'renders a disabled button' do
      render

      button = output.find('button', text: 'Renewals blocked')
      expect(button).to be_disabled
    end
  end
end
