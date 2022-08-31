# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CqlQuery do
  describe '#to_query' do
    context 'with one filter' do
      subject(:cql) { described_class.new(barcode: '1234567890').to_query }

      it { is_expected.to eq 'barcode=="1234567890"' }
    end

    context 'with multiple filters' do
      subject(:cql) { described_class.new(barcode: '1234567890', username: 'testuser').to_query }

      it { is_expected.to eq 'barcode=="1234567890" and username=="testuser"' }
    end

    context 'with special characters that need escaping' do
      subject(:cql) { described_class.new(title: '"quoted"', username: 'testuser*').to_query }

      it { is_expected.to eq 'title=="\\"quoted\\"" and username=="testuser\\*"' }
    end

    context 'with a sort' do
      subject(:cql) { described_class.new(sortby: 'username').to_query }

      it { is_expected.to eq 'sortby username' }
    end
  end
end
