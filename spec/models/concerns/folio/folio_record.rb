# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'folio_record' do
  let(:model) { described_class.new(record) }

  describe '#home_location' do
    context 'when the item has a permanent location' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
             { 'permanentLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } }
      end

      it "returns the item's permanent location" do
        expect(model.home_location).to eq 'BORROWDIR'
      end
    end

    context 'when the item does not have a permanent location' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' => { 'holdingsRecord' => { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } } }
      end

      it "returns the holdings record's effective location" do
        expect(model.home_location).to eq 'BORROWDIR'
      end
    end
  end
end
