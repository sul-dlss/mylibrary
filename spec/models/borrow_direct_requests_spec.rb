# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowDirectRequests do
  subject(:bd_requests) { described_class.new(patron_barcode) }

  let(:patron_barcode) { '123456' }
  let(:in_process_request) do
    instance_double(
      BorrowDirect::RequestQuery::Item,
      request_number: 'STA-123454321',
      request_status: 'IN_PROCESS',
      date_submitted: Time.zone.today - 3.days
    )
  end
  let(:completed_request) do
    instance_double(BorrowDirect::RequestQuery::Item, request_status: 'COMPLETED', title: 'BD Request Title')
  end
  let(:mock_requests) do
    instance_double(BorrowDirect::RequestQuery, requests: [in_process_request, completed_request])
  end

  context 'when successful' do
    before do
      allow(BorrowDirect::RequestQuery).to receive(:new).with(patron_barcode).and_return(mock_requests)
    end

    it 'only return requests with active statuses' do
      expect(bd_requests.requests.length).to be(1)
    end
  end

  context 'when borrow direct returns an error' do
    before do
      allow(BorrowDirect::RequestQuery).to receive(:new).with(patron_barcode).and_raise(
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

    describe '#sort_key' do
      let(:request) { BorrowDirectRequests::Request.new(completed_request) }

      context 'when title' do
        it { expect(request.sort_key(:title)).to eq 'BD Request Title' }
      end

      context 'when date' do
        it { expect(request.sort_key(:date)).to eq "#{Symphony::Request::END_OF_DAYS.strftime('%FT%T')}---BD Request Title" }
      end

      context 'when any other sort value' do
        it { expect(request.sort_key(:something_else)).to eq '' }
      end
    end
  end
end
