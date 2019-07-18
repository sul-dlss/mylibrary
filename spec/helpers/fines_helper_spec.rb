# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinesHelper do
  describe '#nice_status_fee_label' do
    it 'returns the status if it ends with "fee"' do
      expect(helper.nice_status_fee_label('A label with fee')).to eq 'A label with fee'
    end

    it 'returns the status with "fee" applied if it does not end with "fee"' do
      expect(helper.nice_status_fee_label('A label')).to eq 'A label fee'
    end
  end
end
