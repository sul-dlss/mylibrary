# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requests/_request' do
  let(:request_attributes) { {} }
  let(:mock_request) do
    instance_double(
      Symphony::Request,
      author: 'Some Author',
      call_number: '',
      catkey: '12345',
      expiration_date: 1.day.from_now,
      from_ill?: false,
      key: 'abc123',
      pickup_library: 'XYZ',
      placed_date: Time.zone.now,
      library: 'SAL3',
      ready_for_pickup?: false,
      sort_key: '1',
      title: 'A Book',
      waitlist_position: nil,
      cdl_loan_period: nil,
      cdl?: false,
      **request_attributes
    )
  end

  let(:patron) { instance_double(Symphony::Patron, can_modify_requests?: false) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron).and_return(patron)
    end

    render partial: 'requests/request', locals: { request: mock_request }
  end

  it 'links to the item in SearchWorks' do
    expect(rendered).to have_link(
      'View in SearchWorks',
      href: 'https://searchworks.stanford.edu/view/12345'
    )
  end

  context 'when the library is from ILL' do
    let(:request_attributes) { { from_ill?: true } }

    it 'does not include a link to the item in SearchWorks' do
      expect(rendered).not_to have_link('View in SearchWorks')
    end
  end
end
