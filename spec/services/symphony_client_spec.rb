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
end
