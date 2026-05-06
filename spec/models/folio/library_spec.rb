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
