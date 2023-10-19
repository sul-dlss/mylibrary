# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'folio_record' do |args = []|
  let(:model) { described_class.new(*args.dup.unshift(record)) }

  describe '#effective_location_code' do
    let(:record) do
      { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
        'item' =>
          { 'item' =>
          { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } }
    end

    it 'returns the effective location code' do
      expect(model.effective_location_code).to eq 'SUL-BORROW-DIRECT'
    end
  end

  describe '#permanent_location_code' do
    context 'when the item has a permanent location' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
             { 'permanentLocation' => { 'code' => 'MY-PERMANENT-LOCATION' } } } }
      end

      it 'returns the permanent location' do
        expect(model.permanent_location_code).to eq 'MY-PERMANENT-LOCATION'
      end
    end

    context 'when the item does not have a permanent location' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' => { 'holdingsRecord' => { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } } }
      end

      it 'falls back the holdings record effective location' do
        expect(model.permanent_location_code).to eq 'SUL-BORROW-DIRECT'
      end
    end
  end
end
