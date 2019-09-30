# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibraryLocation do
  describe '#additional_pickup_libraries' do
    it 'returns a list of pickup libraries that rejects the current' do
      expect(described_class.new('PAGE-AR').additional_pickup_libraries('ART')).to include(
        'SPEC-COLL'
      )
    end
  end

  describe '#pickup_libraries' do
    it 'provides default pickup libraries' do
      expect(described_class.new('STACKS').pickup_libraries).to include(
        'ART', 'BUSINESS', 'EARTH-SCI', 'EAST-ASIA', 'EDUCATION', 'ENG', 'GREEN',
        'HOPKINS', 'LAW', 'MUSIC', 'SAL', 'SCIENCE'
      )
    end

    it 'provides location specific pickup libraries' do
      expect(described_class.new('PAGE-AR').pickup_libraries).to include(
        'ART', 'SPEC-COLL'
      )
    end

    it 'provides library specific pickup libraries' do
      expect(described_class.new('RUMSEYMAP').pickup_libraries).to include(
        'RUMSEYMAP'
      )
    end
  end
end
