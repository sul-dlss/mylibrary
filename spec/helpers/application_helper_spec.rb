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

  describe '#list_group_item_status_for_checkout' do
    context 'with a recalled item' do
      let(:checkout) { instance_double(Checkout, recalled?: true) }

      it 'is *-danger' do
        expect(helper.list_group_item_status_for_checkout(checkout)).to eq 'list-group-item-danger'
      end
    end

    context 'with an overdue item' do
      let(:checkout) { instance_double(Checkout, recalled?: false, overdue?: true) }

      it 'is *-warning' do
        expect(helper.list_group_item_status_for_checkout(checkout)).to eq 'list-group-item-warning'
      end
    end
  end
end
