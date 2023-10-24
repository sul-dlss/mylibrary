# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Library do
  let(:green_library) do
    {
      id: 'f6b5519e-88d9-413e-924d-9ed96255f72e',
      name: 'Green Library',
      code: 'GREEN',
      campusId: 'c365047a-51f2-45ce-8601-e421ca3615c5',
      metadata: {
        createdDate: '2023-08-10T17:44:48.373+00:00',
        createdByUserId: '58d0aaf6-dcda-4d5e-92da-012e6b7dd766',
        updatedDate: '2023-08-10T17:44:48.373+00:00',
        updatedByUserId: '58d0aaf6-dcda-4d5e-92da-012e6b7dd766'
      }
    }.with_indifferent_access
  end

  # rubocop: disable Rails/RedundantActiveRecordAllMethod
  describe '.all' do
    it 'returns an array of libraries' do
      expect(described_class.all.first).to be_a described_class
    end
  end
  # rubocop: enable Rails/RedundantActiveRecordAllMethod

  describe '.find_by_code' do
    it 'returns a library' do
      expect(described_class.find_by_code('GREEN')).to be_a described_class
    end

    it 'returns nil for an unknown code' do
      expect(described_class.find_by_code('SOME_CODE')).to be_nil
    end
  end

  describe '.find_by_id' do
    it 'returns a library' do
      expect(described_class.find_by_id('c1a86906-ced0-46cb-8f5b-8cef542bdd00')).to be_a described_class
    end

    it 'returns nil for an unknown code' do
      expect(described_class.find_by_id('123456')).to be_nil
    end
  end

  describe '.from_dynamic' do
    subject(:green) { described_class.from_dynamic(green_library) }

    it 'stores the id' do
      expect(green.id).to eq 'f6b5519e-88d9-413e-924d-9ed96255f72e'
    end

    it 'stores the code' do
      expect(green.code).to eq 'GREEN'
    end

    it 'stores the name' do
      expect(green.name).to eq 'Green Library'
    end
  end
end
