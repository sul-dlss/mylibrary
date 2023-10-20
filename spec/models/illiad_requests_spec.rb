# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IlliadRequests do
  subject(:ill_request) { described_class.new(patron_sunet_id) }

  let(:patron_sunet_id) { 'sunet' }
  let(:hold_recall_result) do
    '{"TransactionNumber":347070,
      "Username":"sunet",
      "LoanAuthor":"Gilbert Roy",
      "LoanTitle":"Disney Motion Pictures",
      "CreationDate":"2023-10-11T10:49:41.783",
      "ItemInfo4":"GREEN",
      "NotWantedAfter":"2024-10-11",
      "CallNumber":"ABC"}'
  end
  let(:scan_result) do
    '{"TransactionNumber":12345,
      "Username":"sunet",
      "PhotoArticleAuthor":"Frederick Wright",
      "PhotoJournalTitle":"String Beans",
      "CreationDate":"2023-10-12T10:49:41.783",
      "ItemInfo4":"GREEN",
      "CallNumber":"DEF"}'
  end
  let(:transaction_results) do
    "[#{hold_recall_result},#{scan_result}]"
  end

  context 'when successful, it correctly retrieves transaction requests' do
    before do
      stub_request(:get, "#{Settings.sul_illiad}ILLiadWebPlatform/Transaction/UserRequests/#{patron_sunet_id}")
        .to_return(status: 200, body: transaction_results, headers: {})
    end

    let(:request_results) { ill_request.request! }

    it 'correctly returns request objects' do
      expect(request_results.length).to be(2)
    end
  end

  describe 'IlliadRequests::Request' do
    let(:ill_hold_request) do
      IlliadRequests::Request.new(JSON.parse(hold_recall_result))
    end

    let(:ill_scan_request) do
      IlliadRequests::Request.new(JSON.parse(scan_result))
    end

    it 'correctly identified hold recall result as not being type scan' do
      expect(ill_hold_request.scan_type?).to be(false)
    end

    it 'correctly retrieves title for non-scan transaction' do
      expect(ill_hold_request.title).to eq('Disney Motion Pictures')
    end

    it 'correctly retrieves author for non-scan transaction' do
      expect(ill_hold_request.author).to eq('Gilbert Roy')
    end

    it 'correctly identified scan result as type scan' do
      expect(ill_scan_request.scan_type?).to be(true)
    end

    it 'correctly retrieves title for scan transaction' do
      expect(ill_scan_request.title).to eq('String Beans')
    end

    it 'correctly retrieves author for scan transaction' do
      expect(ill_scan_request.author).to eq('Frederick Wright')
    end
  end
end
