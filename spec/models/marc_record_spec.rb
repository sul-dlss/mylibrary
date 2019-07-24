# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarcRecord do
  subject(:record) { described_class.new(marc.with_indifferent_access) }

  describe '#format_main' do
    context 'with a book' do
      let(:marc) do
        {
          leader: '04473cam a2200313Ia 4500',
          fields: [
            {
              tag: '008',
              subfields: [
                {
                  code: '_',
                  data: '040202s2003    fi g     b    000 0deng d'
                }
              ]
            }
          ]
        }
      end

      it 'maps to Book' do
        expect(record.format_main).to eq ['Book']
      end
    end
  end
end
