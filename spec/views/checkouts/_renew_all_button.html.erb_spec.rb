# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'checkouts/_renew_all_button.html.erb' do
  subject(:output) { Capybara.string(rendered) }

  let(:patron) { instance_double(Patron, checkouts: checkouts, can_renew?: true) }
  let(:checkouts) { [instance_double(Checkout, renewable?: true)] }

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

    expect(output).to have_css('a.btn', text: 'Renew 1 eligible item')
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
