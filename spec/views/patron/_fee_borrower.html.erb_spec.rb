# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patron/_fee_borrower.html.erb' do
  let(:patron_options) { {} }
  let(:patron) do
    instance_double(
      Patron,
      first_name: 'Jane',
      last_name: 'Stanford',
      patron_type: nil,
      barred?: false,
      status: 'Expired',
      expired_date: Time.zone.today - 10.days,
      borrow_limit: 25,
      email: nil,
      **patron_options
    )
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron).and_return(patron)
    end
  end

  describe 'Privileges Expire' do
    before { render }

    context 'when the patron has an expired_date' do
      it { expect(rendered).to have_css('dt', text: 'Privileges expire') }
    end

    context 'when the patron does not have an expired_date' do
      let(:patron_options) { { expired_date: nil } }

      it { expect(rendered).not_to have_css('dt', text: 'Privileges expire') }
    end
  end

  describe 'eResource Access Restrictions' do
    before { render }

    it { expect(rendered).to have_css('dt', text: 'eResource access') }
    it { expect(rendered).to have_css('dd', text: 'In-library only') }
  end

  describe 'borrow_limit' do
    before { render }

    it { expect(rendered).to have_css('dt', text: 'Borrower limit') }
    it { expect(rendered).to have_css('dd', text: '25') }
  end
end
