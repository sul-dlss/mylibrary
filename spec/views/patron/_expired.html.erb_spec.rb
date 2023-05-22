# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patron/_expired' do
  let(:patron_options) { {} }
  let(:patron) do
    instance_double(
      Symphony::Patron,
      first_name: 'Jane',
      last_name: 'Stanford',
      patron_type: nil,
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
