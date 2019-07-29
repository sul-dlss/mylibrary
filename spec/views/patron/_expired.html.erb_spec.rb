# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patron/_expired.html.erb' do
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
      email: nil,
      **patron_options
    )
  end

  before do
    controller.singleton_class.class_eval do
      protected

      def patron; end

      helper_method :patron
    end

    allow(view).to receive(:patron).and_return(patron)
  end

  it 'renders data about when the privilegs expired' do
    render

    expect(rendered).to have_css('dt', text: 'Privileges expired')
  end
end
