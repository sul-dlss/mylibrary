# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::ServicePoint do
  let(:service_points) do
    build(:service_points)
  end

  before do
    allow(described_class).to receive_messages(
      all: service_points
    )
  end

  # rubocop: disable Rails/RedundantActiveRecordAllMethod
  describe '.all' do
    it 'returns an array of service points' do
      expect(described_class.all.first).to be_a described_class
    end

    it 'returns all the service points' do
      expect(described_class.all.size).to eq(4)
    end
  end
  # rubocop: enable Rails/RedundantActiveRecordAllMethod

  describe '.default_service_points' do
    it 'returns only the default service points' do
      expect(described_class.default_service_points.size).to eq(2)
    end
  end

  describe '.name_by_code' do
    it 'returns the name of the service point' do
      expect(described_class.name_by_code('GREEN-LOAN')).to eq 'Green Library'
    end

    it 'returns nil for an unknown code' do
      expect(described_class.name_by_code('FAKELIB')).to be_nil
    end
  end

  describe '.find_by_id' do
    it 'returns the service point' do
      expect(described_class.find_by_id('a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d')).to be_a described_class # rubocop:disable Rails/DynamicFindBy
    end

    it 'returns nil for an unknown id' do
      expect(described_class.find_by_id('fake-123-345')).to be_nil # rubocop:disable Rails/DynamicFindBy
    end
  end
end
