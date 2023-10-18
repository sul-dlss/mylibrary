# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Location do
  let(:green_reserves) do
    {
      id: '4a911835-3488-4d26-9293-bdc625c9afce',
      name: 'Green Reserves',
      code: 'GRE-CRES',
      discoveryDisplayName: 'On reserve: Ask at Green circulation desk',
      isActive: true,
      institutionId: '8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929',
      campusId: 'c365047a-51f2-45ce-8601-e421ca3615c5',
      libraryId: 'f6b5519e-88d9-413e-924d-9ed96255f72e',
      details: {
        stackmapBaseUrl: 'https://stanford.stackmap.com/json/',
        searchworksTreatTemporaryLocationAsPermanentLocation: 'true'
      },
      primaryServicePoint: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
      servicePointIds: [
        'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d'
      ],
      servicePoints: [],
      metadata: {
        createdDate: '2023-08-10T17:46:10.100+00:00',
        createdByUserId: '58d0aaf6-dcda-4d5e-92da-012e6b7dd766',
        updatedDate: '2023-10-02T17:01:54.917+00:00',
        updatedByUserId: '2f7f4956-c95a-47ba-95f8-395354707b6f'
      }
    }.with_indifferent_access
  end

  # rubocop: disable Rails/RedundantActiveRecordAllMethod
  describe '.all' do
    it 'returns an array of locations' do
      expect(described_class.all.first).to be_a described_class
    end
  end
  # rubocop: enable Rails/RedundantActiveRecordAllMethod

  describe '.find_by_code' do
    it 'returns a location' do
      expect(described_class.find_by_code('GRE-STACKS')).to be_a described_class
    end

    it 'returns nil for an unknown code' do
      expect(described_class.find_by_code('SOME_CODE')).to be_nil
    end
  end

  describe '.find_by_id' do
    it 'returns a location' do
      expect(described_class.find_by_id('4573e824-9273-4f13-972f-cff7bf504217')).to be_a described_class
    end

    it 'returns nil for an unknown code' do
      expect(described_class.find_by_id('f5c58187-3db6-4bda-b1bf-e5f0717e2149')).to be_nil
    end
  end

  describe '.from_dynamic' do
    subject(:green) { described_class.from_dynamic(green_reserves) }

    it 'stores the id' do
      expect(green.id).to eq '4a911835-3488-4d26-9293-bdc625c9afce'
    end

    it 'stores the library' do
      expect(green.library.name).to eq 'Green Library'
    end

    it 'stores the library id' do
      expect(green.library_id).to eq 'f6b5519e-88d9-413e-924d-9ed96255f72e'
    end

    it 'stores the code' do
      expect(green.code).to eq 'GRE-CRES'
    end

    it 'stores the discovery_display_name' do
      expect(green.discovery_display_name).to eq 'On reserve: Ask at Green circulation desk'
    end

    it 'stores the name' do
      expect(green.name).to eq 'Green Reserves'
    end

    it 'stores the details' do
      expect(green.details).to match a_hash_including('searchworksTreatTemporaryLocationAsPermanentLocation' => 'true')
    end

    it 'stores the primary_service_point_id' do
      expect(green.primary_service_point_id).to eq 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d'
    end
  end
end
