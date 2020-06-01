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
      group?: false,
      barred?: false,
      fee_borrower?: false,
      expired_date: nil,
      email: 'jane@stanford.edu',
      checkouts: [],
      requests: [],
      fines: [],
      remaining_checkouts: nil,
      to_partial_path: 'patron/patron',
      can_renew?: true,
      can_schedule_green_access?: false,
      can_schedule_green_pickup?: false,
      can_schedule_special_collections_visit?: false,
      **patron_options
    )
  end

  before do
    controller.singleton_class.class_eval do
      protected

      def patron_or_group; end

      helper_method :patron_or_group
    end

    stub_template 'shared/_navigation.html.erb' => 'Navigation'
    allow(view).to receive(:patron_or_group).and_return(patron)
  end

  context 'when the patron is barred' do
    let(:patron_options) { { barred?: true, status: 'Contact us' } }

    it 'links to contact form' do
      render

      expect(rendered).to have_link('Contact us')
    end
  end

  context 'when the patron is not barred' do
    it 'renders the status without a link' do
      render

      expect(rendered).not_to have_link('OK')
    end

    it 'renders the patron status' do
      render

      expect(rendered).to have_css('dd', text: 'OK')
    end
  end
end
