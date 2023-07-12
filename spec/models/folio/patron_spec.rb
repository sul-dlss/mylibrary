# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Patron do
  let(:sponsor) do
    build(:sponsor_patron, custom_properties: {})
  end
  let(:proxy) do
    build(:proxy_patron, custom_properties: {})
  end

  context 'when the patron is a Sponsor' do
    describe '#checkouts' do
      subject(:checkouts) { sponsor.checkouts }

      it 'returns checkouts of the patron' do
        expect(checkouts.first.record.dig('item', 'title')).to eq 'Blue-collar Broadway'
      end

      it 'returns the correct number of checkouts' do
        expect(checkouts.length).to eq 1
      end
    end

    describe '#group_checkouts' do
      subject(:group_checkouts) { sponsor.group_checkouts }

      it 'returns checkouts made by the proxies of that sponsor' do
        expect(group_checkouts.first.record.dig('item', 'title')).to eq 'Music, sound, language, theater'
      end

      it 'returns the correct number of group checkouts' do
        expect(group_checkouts.length).to eq 2
      end

      it 'does not return the personal checkouts of the sponsor' do
        expect(group_checkouts.none? do |checkout|
                 checkout.record.dig('item', 'title') == 'Blue-collar Broadway'
               end).to be true
      end
    end
  end

  context 'when the patron is a Proxy' do
    describe '#checkouts' do
      subject(:checkouts) { proxy.checkouts }

      it 'returns the personal checkouts of the patron' do
        expect(checkouts.first.record.dig('item', 'title')).to eq 'Sci-fi architecture.'
      end

      it 'returns the correct number of personal checkouts' do
        expect(checkouts.length).to eq 1
      end
    end

    describe '#group_checkouts' do
      subject(:group_checkouts) { proxy.group_checkouts }

      it 'returns an empty array for group_checkouts on a proxy' do
        expect(group_checkouts).to eq []
      end
    end
  end
end
