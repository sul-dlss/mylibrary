# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'summaries/index.html.erb' do
  let(:patron_options) { {} }
  let(:patron) do
    instance_double(
      Patron,
      first_name: 'Jane',
      last_name: 'Stanford',
      patron_type: '',
      status: 'OK',
      borrow_limit: nil,
      proxy_borrower?: false,
      fee_borrower?: false,
      expired_date: nil,
      email: 'jane@stanford.edu',
      checkouts: [],
      requests: [],
      fines: [],
      remaining_checkouts: nil,
      **patron_options
    )
  end

  before do
    stub_template 'shared/_navigation.html.erb' => 'Navigation'
    assign(:patron, patron)
  end

  context 'when the patron has an expired_date' do
    context 'when the user is a fee_borrower' do
      let(:patron_options) { { expired_date: Time.zone.today, fee_borrower?: true } }

      it 'renders data about when the privilegs expire' do
        render

        expect(rendered).to have_css('dt', text: 'Privileges expire')
      end
    end
  end

  context 'when the patron does not have an expired date' do
    let(:patron_options) { { fee_borrower?: true } }

    it 'is not displayed (even for fee borrowers)' do
      render

      expect(rendered).not_to have_css('dt', text: 'Privileges expire')
    end
  end
end
