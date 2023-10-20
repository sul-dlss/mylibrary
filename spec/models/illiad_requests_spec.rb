# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IlliadRequests do
  subject(:ill_request) { described_class.new(patron_sunet_id) }

  let(:patron_sunet_id) { 'sunet' }
  let(:transaction_results) do
    '[{"TransactionNumber":347070,
      "Username":"sunet",
      "LoanAuthor":"Gilbert Roy",
      "LoanTitle":"Disney Motion Pictures",
      "CreationDate":"2023-10-11T10:49:41.783",
      "ItemInfo4":"GREEN",
      "NotWantedAfter":"2024-10-11",
      "CallNumber":"ABC"},
      {"TransactionNumber":12345,
      "Username":"sunet",
      "PhotoArticleAuthor":"Frederick Wright",
      "PhotoJournalTitle":"String Beans",
      "CreationDate":"2023-10-12T10:49:41.783",
      "ItemInfo4":"GREEN",
      "CallNumber":"DEF"}]'
  end

  context 'when successful, it correctly maps information' do
    before do
      stub_request(:get, "#{Settings.sul_illiad}ILLiadWebPlatform/Transaction/UserRequests/#{patron_sunet_id}")
        .to_return(status: 200, body: transaction_results, headers: {})
    end

    let(:request_results) { ill_request.request! }

    it 'correctly returns request objects' do
      expect(request_results.length).to be(2)
    end

    it 'correctly retrieves title for non-scan transaction' do
      expect(request_results[0].title).to eq('Disney Motion Pictures')
    end

    it 'correctly retrieves author for non-scan transaction' do
      expect(request_results[0].author).to eq('Gilbert Roy')
    end

    it 'correctly retrieves title for scan transaction' do
      expect(request_results[1].title).to eq('String Beans')
    end

    it 'correctly retrieves author for scan transaction' do
      expect(request_results[1].author).to eq('Frederick Wright')
    end
  end
end
