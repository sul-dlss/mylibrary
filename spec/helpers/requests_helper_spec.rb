# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsHelper do
  describe '#request_location_options' do
    let(:request) { instance_double(Request, pickup_library: 'GREEN', home_location: 'STACKS') }

    it 'creates options for a requests location to be changed' do
      options = helper.request_location_options(request)
      expect(options).to have_css 'option', count: 12
    end

    it 'creates options with value and text' do
      options = helper.request_location_options(request)
      expect(options).to have_css 'option[value="HOPKINS"]', text: 'Marine Biology Library (Miller)'
    end
  end
end
