# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SummariesHelper do
  describe '#scheduler_data_param' do
    it '"encodes" all values and returns the hash as a URL query' do
      expect(
        scheduler_data_param({ blah: 'Jane Stanford', other_blah: 'Hello@example.com' })
      ).to eq 'blah=Jane%20Stanford&other_blah=Hello%40example.com'
    end
  end
end
