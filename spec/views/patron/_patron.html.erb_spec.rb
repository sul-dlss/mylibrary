# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patron/_patron' do
  let(:patron_options) { {} }
  let(:patron) do
    instance_double(
      Folio::Patron,
      first_name: 'Jane',
      last_name: 'Stanford',
      barred?: false,
      fee_borrower?: false,
      expired?: false,
      status: 'Expired',
      expired_date: Time.zone.today - 10.days,
      proxy_borrower?: false,
      borrow_limit: nil,
      email: nil,
      **patron_options
    )
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron).and_return(patron)
    end
  end

  describe 'Privileges expire' do
    before { render }

    context 'when the user does not have an expire_date' do
      let(:patron_options) { { expired_date: nil } }

      it { expect(rendered).to have_no_css('dt', text: 'Privileges expire') }
    end

    context 'when the user is not a proxy borrower' do
      it { expect(rendered).to have_no_css('dt', text: 'Privileges expire') }
    end

    context 'when the user is a proxy borrower' do
      let(:patron_options) { { proxy_borrower?: true } }

      it { expect(rendered).to have_css('dt', text: 'Privileges expire') }
    end
  end

  context 'with an expired patron' do
    let(:patron_options) { {} }
    let(:patron) do
      instance_double(
        Folio::Patron,
        first_name: 'Jane',
        last_name: 'Stanford',
        proxy_borrower?: false,
        fee_borrower?: false,
        expired?: true,
        borrow_limit: nil,
        barred?: false,
        status: 'Expired',
        expired_date: Time.zone.today - 10.days,
        email: nil,
        **patron_options
      )
    end

    before do
      without_partial_double_verification do
        allow(view).to receive(:patron).and_return(patron)
      end
    end

    it 'renders data about when the privilegs expired' do
      render

      expect(rendered).to have_css('dt', text: 'Privileges expired')
    end
  end

  context 'with a fee borrower' do
    let(:patron_options) { {} }
    let(:patron) do
      instance_double(
        Folio::Patron,
        first_name: 'Jane',
        last_name: 'Stanford',
        fee_borrower?: true,
        proxy_borrower?: false,
        expired?: false,
        barred?: false,
        status: 'OK',
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

        it { expect(rendered).to have_no_css('dt', text: 'Privileges expire') }
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
end
