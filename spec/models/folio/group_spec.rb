# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Group do
  let(:sponsor) do
    build(:sponsor_patron, custom_properties: {})
  end
  let(:sponsor_group) { sponsor.group }
  let(:proxy) do
    build(:proxy_patron, custom_properties: {})
  end
  let(:proxy_group) { proxy.group }

  context 'when the patron is a Sponsor' do
    describe '#member_list' do
      subject(:member_list) { sponsor_group.member_list }

      it 'returns the group members' do
        expect(member_list.length).to eq 2
      end

      it 'returns the correct first member' do
        expect(member_list.first.dig('proxyUser', 'personal', 'firstName')).to eq 'Piper'
      end
    end
  end

  context 'when the patron is a Proxy' do
    describe '#member_list' do
      subject(:member_list) { proxy_group.member_list }

      before do
        allow(proxy_group).to receive(:sponsor).and_return(sponsor)
      end

      it 'returns the group members' do
        expect(member_list.length).to eq 2
      end

      it 'returns the correct first member' do
        expect(member_list.first.dig('proxyUser', 'personal', 'firstName')).to eq 'Piper'
      end
    end
  end
end
