# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Policy do
  subject(:policy) { described_class.new(record) }

  let(:record) { { key: '1', fields: fields }.with_indifferent_access }
  let(:fields) { { description: '0', displayName: '140D', periodCount: 140 } }

  describe '#key' do
    it 'returns the policy key' do
      expect(policy.key).to eq '1'
    end
  end

  describe 'field access' do
    it 'has read-only accessors to arbitrary field data' do
      expect(policy).to have_attributes(fields)
    end
  end
end
