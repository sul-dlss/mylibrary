# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::ServicePoint do
  let(:service_points) do
    build(:service_points)
  end

  before do
    allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(described_class, service_points))
  end

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
end
