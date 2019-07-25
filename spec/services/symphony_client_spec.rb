# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SymphonyClient do
  let(:client) { subject }

  before do
    stub_request(:post, 'https://example.com/symws/user/staff/login')
      .with(body: Settings.symws.login_params.to_h)
      .to_return(body: { sessionToken: 'tokentokentoken' }.to_json)
  end

  describe '#ping' do
    it 'returns true if we can connect to symws' do
      expect(client.ping).to eq true
    end

    context 'when unable to connect' do
      before do
        stub_request(:post, 'https://example.com/symws/user/staff/login').to_timeout
      end

      it 'returns false' do
        expect(client.ping).to eq false
      end
    end
  end

  describe '#session_token' do
    it 'retrieves a session token from symws' do
      expect(client.session_token).to eq 'tokentokentoken'
    end
  end

  describe '#login' do
    before do
      stub_request(:post, 'https://example.com/symws/user/patron/authenticate')
        .with(body: { barcode: '123', password: '321' })
        .to_return(body: { patronKey: 'key' }.to_json)
    end

    it 'authenticates the user against symphony' do
      expect(client.login('123', '321')).to include 'patronKey' => 'key'
    end
  end

  describe '#login_by_sunetid' do
    before do
      stub_request(:get, 'https://example.com/symws/user/patron/search?includeFields=*&q=webAuthID:sunetid')
        .to_return(body: { result: [{ key: 'key' }] }.to_json)
    end

    it 'authenticates the user against symphony' do
      expect(client.login_by_sunetid('sunetid')).to include 'key' => 'key'
    end
  end

  describe '#patron_info' do
    before do
      stub_request(:get, 'https://example.com/symws/user/patron/key/somepatronkey')
        .with(query: hash_including(includeFields: match(/\*/)))
        .to_return(body: { key: 'somepatronkey' }.to_json)
    end

    it 'authenticates the user against symphony' do
      expect(client.patron_info('somepatronkey')).to include 'key' => 'somepatronkey'
    end
  end

  describe '#renew_item' do
    before do
      stub_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
        .with(body: { item: { resource: 'item', key: '123' } })
        .to_return(status: 200)
    end

    it 'renews an item in symphony' do
      expect(client.renew_item('item', '123')).to have_attributes status: 200
    end
  end

  describe '#renew_items' do
    before do
      stub_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
        .with(body: { item: { resource: 'item', key: '123' } })
        .to_return(status: 200)
      stub_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
        .with(body: { item: { resource: 'item', key: 'invalid' } })
        .to_return(status: 400)
    end

    let(:checkouts) do
      [
        instance_double(Checkout, resource: 'item', item_key: '123', title: 'A'),
        instance_double(Checkout, resource: 'item', item_key: 'invalid', title: 'B')
      ]
    end

    it 'returns success + error values for individual renewal requests in symphony' do
      actual = client.renew_items(checkouts)

      expect(actual).to include success: [/"A" was renewed/],
                                error: [/"B" was not renewed/]
    end
  end
end
