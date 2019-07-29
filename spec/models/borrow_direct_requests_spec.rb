# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowDirectRequests do
  subject(:bd_requests) { described_class.new(patron) }

  let(:patron) { instance_double(Patron, barcode: '123456') }
  let(:in_process_request) do
    instance_double(
      BorrowDirect::RequestQuery::Item,
      request_number: 'STA-123454321',
      request_status: 'IN_PROCESS',
      date_submitted: Time.zone.today - 3.days
    )
  end
  let(:completed_request) { instance_double(BorrowDirect::RequestQuery::Item, request_status: 'COMPLETED') }
  let(:mock_requests) do
    instance_double(BorrowDirect::RequestQuery, requests: [in_process_request, completed_request])
  end

  context 'when successful' do
    before do
      allow(BorrowDirect::RequestQuery).to receive(:new).with(patron.barcode).and_return(mock_requests)
    end

    it 'only return requests with active statuses' do
      expect(bd_requests.requests.length).to be(1)
    end
  end

  context 'when borrow direct returns an error' do
    before do
      allow(BorrowDirect::RequestQuery).to receive(:new).with(patron.barcode).and_raise(
        BorrowDirect::Error, 'Item not Found'
      )
    end

    it 'returns an empty array' do
      expect(bd_requests.requests).to eq([])
    end
  end

  describe 'BorrowDirectRequests::Request' do
    let(:request) do
      BorrowDirectRequests::Request.new(in_process_request)
    end

    it 'delegates methods to the given request oboject' do
      expect(request.date_submitted).to eq in_process_request.date_submitted
    end

    it 'returns the request_number as the key' do
      expect(request.key).to eq in_process_request.request_number
    end

    it { expect(request).not_to be_ready_for_pickup }

    context 'when in an active state' do
      it { expect(request).to be_active }
    end

    context 'when not in an active state' do
      let(:request) do
        BorrowDirectRequests::Request.new(completed_request)
      end

      it { expect(request).not_to be_active }
    end
  end
end
