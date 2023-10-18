# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requests/_request' do
  let(:request_attributes) { {} }
  let(:mock_request) do
    instance_double(
      Folio::Request,
      author: 'Some Author',
      call_number: '',
      catkey: '12345',
      expiration_date: 1.day.from_now,
      from_ill?: false,
      key: 'abc123',
      service_point_name: 'XYZ Library',
      placed_date: Time.zone.now,
      library_name: 'SAL3 (off-campus storage)',
      ready_for_pickup?: false,
      sort_key: '1',
      title: 'A Book',
      waitlist_position: nil,
      patron_key: 'patronkey123',
      manage_request_link: nil,
      **request_attributes
    )
  end

  let(:patron) { instance_double(Folio::Patron, can_modify_requests?: true, group: group_instance) }
  let(:group_instance) { instance_double(Folio::Group, member_name: 'Piper Proxy') }

  before do
    without_partial_double_verification do
      allow(view).to receive_messages(params: { group: true }, patron:) # Set params[:group] to true
    end
    render partial: 'requests/request', locals: { request: mock_request, group: true }
  end

  it 'links to the item in SearchWorks' do
    expect(rendered).to have_link(
      'View in SearchWorks',
      href: 'https://searchworks.stanford.edu/view/12345'
    )
  end

  context 'when the request was made by a proxy' do
    it 'displays proxy requester name' do
      expect(rendered).to include('Borrower:', 'Piper Proxy')
    end
  end
end
