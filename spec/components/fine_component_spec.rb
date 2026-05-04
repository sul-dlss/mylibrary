# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FineComponent, type: :component do
  subject(:component) { described_class.new(fine: fine, patron: nil) }

  let(:fine) do
    instance_double(Folio::Account, nice_status: 'A label with fee')
  end

  describe '#nice_status_fee_label' do
    it 'returns the status if it ends with "fee"' do
      expect(component.nice_status_fee_label).to eq 'A label with fee'
    end

    context 'when the status does not end with "fee"' do
      let(:fine) { instance_double(Folio::Account, nice_status: 'A label') }

      it 'returns the status with "fee" applied if it does not end with "fee"' do
        expect(component.nice_status_fee_label).to eq 'A label fee'
      end
    end
  end
end
