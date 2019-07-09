# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#active_page_class' do
    it 'when the controller_name matches the provided name' do
      allow(helper).to receive(:controller_name).and_return 'summaries'
      expect(helper.active_page_class('summaries')).to eq 'active'
    end
    it 'when the controller_name does not match' do
      expect(helper.active_page_class('summaries')).to be_nil
    end
  end
end
