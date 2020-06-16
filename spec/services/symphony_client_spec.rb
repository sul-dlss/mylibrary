# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SymphonyClient do
  let(:client) { subject }

  let(:unavailable) do
    { status: '503',
      body: '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
       <html>
        <head>
          <title>503 Service Unavailable</title>
        </head>
        <body>
          <h1>Service Unavailable</h1>
            <p>The server is temporarily unable to service your request due to maintenance downtime
             or capacity problems. Please try again later.</p>
        </body>
       </html>' }
  end

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
    context 'when symphony is available' do
      it 'retrieves a session token from symws' do
        expect(client.session_token).to eq 'tokentokentoken'
      end
    end

    context 'when symphony is unavailable' do
      before do
        stub_request(:post, 'https://example.com/symws/user/staff/login')
          .with(body: Settings.symws.login_params.to_h)
          .to_return(unavailable)
      end

      it 'retrieves a session token from symws' do
        expect(client.session_token).to be nil
      end
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

    context 'when requesting item details' do
      it 'requests the item details for checkouts' do
        client.patron_info('somepatronkey', item_details: { circRecordList: true })

        expect(WebMock).to have_requested(:get, 'https://example.com/symws/user/patron/key/somepatronkey')
          .with(query: hash_including(includeFields: match(/circRecordList{.*,item{.*}}/)))
      end

      it 'requests the item details for requests' do
        client.patron_info('somepatronkey', item_details: { holdRecordList: true })

        expect(WebMock).to have_requested(:get, 'https://example.com/symws/user/patron/key/somepatronkey')
          .with(query: hash_including(includeFields: match(/holdRecordList{.*,item{.*}}/)))
      end

      it 'requests the item details for fines' do
        client.patron_info('somepatronkey', item_details: { blockList: true })

        expect(WebMock).to have_requested(:get, 'https://example.com/symws/user/patron/key/somepatronkey')
          .with(query: hash_including(includeFields: match(/blockList{.*,item{.*}}/)))
      end
    end

    context 'when symphony returns no patron info' do
      before do
        allow(client).to receive(:authenticated_request).and_return(
          instance_double('HTTP::Response', body: unavailable[:body], status: unavailable[:status])
        )
      end

      it 'rescues an error and returns nil' do
        expect(client.patron_info('somepatronkey')).to be nil
      end
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

    context 'when item has a title-level hold' do
      before do
        stub_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
          .with(body: { item: { resource: 'item', key: '456' } })
          .to_return(status: 500, body: error_prompt)
          .then.to_return(status: 200)
      end

      let(:error_prompt) do
        { dataMap: { promptType: 'CIRC_HOLDS_OVRCD' } }.to_json
      end

      it 'renews an item in symphony' do
        expect(client.renew_item('item', '456')).to have_attributes status: 200
      end

      # rubocop:disable RSpec/ExampleLength
      it 'sends an override request for a title-level hold' do
        client.renew_item('item', '456')

        expect(a_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
          .with(
            body: { item: { resource: 'item', key: '456' } },
            headers: { 'SD-Prompt-Return': 'CIRC_HOLDS_OVRCD/PASSWORD' }
          )).to have_been_made.once
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context 'when item has a different kind of hold error' do
      before do
        stub_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
          .with(body: { item: { resource: 'item', key: '456' } })
          .to_return(status: 500, body: fake_error_prompt)
      end

      let(:fake_error_prompt) do
        { dataMap: { promptType: 'CIRC_HOLDS_OTHER_ERROR' } }.to_json
      end

      it 'fails to renews an item in symphony' do
        expect(client.renew_item('item', '456')).to have_attributes status: 500
      end
    end

    context 'when item has a non-json error status' do
      before do
        stub_request(:post, 'https://example.com/symws/circulation/circRecord/renew')
          .with(body: { item: { resource: 'item', key: '456' } })
          .to_return(status: 500, body: '<html>error</html>')
      end

      it 'fails to renews an item in symphony' do
        expect(client.renew_item('item', '456')).to have_attributes status: 500
      end
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

    it 'returns successful + errored titles for individual renewal requests in symphony' do
      actual = client.renew_items(checkouts)

      expect(actual).to include success: [checkouts.first],
                                error: [checkouts.last]
    end
  end
end
