# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples Folio::RecordLocation do
  subject(:record_location) { described_class.new(record) }

  describe '#from_ill?' do
    context 'when record is from borrow direct' do
      let(:record) do
        { 'item' =>
             { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } }
      end

      it { expect(record_location).to be_from_ill }
    end

    context 'when record is from Green Library' do
      let(:record) do
        { 'item' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' } } }
      end

      it { expect(record_location).not_to be_from_ill }
    end
  end

  describe '#library_name' do
    context 'when record is from borrow direct' do
      let(:record) do
        { 'item' =>
          { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } }
      end

      it 'returns the name of the ILL location' do
        expect(record_location.library_name).to eq 'Borrow Direct'
      end
    end

    context 'when record is from Green Library' do
      let(:record) do
        { 'item' =>
          { 'permanentLocation' => { 'code' => 'GRE-STACKS' } } }
      end

      it "returns the name of the permanent location's library" do
        expect(record_location.library_name).to eq 'Green Library'
      end
    end

    context 'when the temporary location should be treated as the permanent location' do
      let(:record) do
        { 'item' =>
          { 'effectiveLocation' => { 'code' => 'GRE-CRES' } } }
      end

      it "returns the name of the temporary location's library" do
        expect(record_location.library_name).to eq 'Green Library'
      end
    end
  end

  describe '#effective_location' do
    let(:record) do
      { 'item' =>
        { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } }
    end

    it 'returns the effective location' do
      expect(record_location.effective_location&.code).to eq 'SUL-BORROW-DIRECT'
    end
  end

  describe '#permanent_location' do
    context 'when the item has a permanent location' do
      let(:record) do
        { 'item' =>
          { 'permanentLocation' => { 'code' => 'GRE-STACKS' } } }
      end

      it 'returns the permanent location' do
        expect(record_location.permanent_location&.code).to eq 'GRE-STACKS'
      end
    end

    context 'when the item does not have a permanent location' do
      let(:record) do
        { 'item' => { 'holdingsRecord' => { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } }
      end

      it 'falls back to the holdings record effective location' do
        expect(record_location.permanent_location&.code).to eq 'SUL-BORROW-DIRECT'
      end
    end
  end
end
