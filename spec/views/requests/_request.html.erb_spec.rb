# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requests/_request.html.erb' do
  let(:request_attributes) { {} }
  let(:mock_request) do
    instance_double(
      Request,
      author: 'Some Author',
      call_number: '',
      catkey: '12345',
      expiration_date: Time.zone.now + 1.day,
      from_borrow_direct?: false,
      key: 'abc123',
      pickup_library: 'XYZ',
      placed_date: Time.zone.now,
      library: 'SAL3',
      ready_for_pickup?: false,
      sort_key: '1',
      title: 'A Book',
      waitlist_position: nil,
      **request_attributes
    )
  end

  let(:patron) { instance_double(Patron, can_modify_requests?: false) }

  before do
    controller.singleton_class.class_eval do
      protected

      def patron; end
      helper_method :request, :patron
    end

    allow(view).to receive(:patron).and_return(patron)

    render partial: 'requests/request', locals: { request: mock_request }
  end

  it 'links to the item in SearchWorks' do
    expect(rendered).to have_link(
      'View in SearchWorks',
      href: 'https://searchworks.stanford.edu/view/12345'
    )
  end

  context 'when the library is BORROW_DIRECT' do
    let(:request_attributes) { { from_borrow_direct?: true } }

    it 'does not include a link to the item in SearchWorks' do
      expect(rendered).not_to have_link('View in SearchWorks')
    end
  end
end
