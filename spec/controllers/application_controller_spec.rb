# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  let(:mock_client) { instance_double(FolioClient) }

  let(:user) do
    User.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')
  end

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  describe '#current_user' do
    before do
      warden.set_user(user)
    end

    it 'returns the warden user' do
      expect(controller.current_user).to have_attributes username: 'somesunetid',
                                                         patron_key: '513a9054-5897-11ee-8c99-0242ac120002'
    end
  end

  describe '#current_user?' do
    context 'with a logged in user' do
      before do
        warden.set_user(user)
      end

      it 'is true' do
        expect(controller.current_user?).to be true
      end
    end

    context 'without a logged in user' do
      it 'is false' do
        expect(controller.current_user?).to be false
      end
    end
  end

  describe '#patron' do
    context 'with a logged in user' do
      let(:patron_info) do
        {
          'user' => { 'active' => false, 'manualBlocks' => [], 'blocks' => [] },
          'loans' => [],
          'holds' => [],
          'accounts' => []
        }
      end

      before do
        allow(mock_client).to receive_messages(patron_info:)
        warden.set_user(user)
      end

      it 'is a new instance of the Patron class' do
        expect(controller.patron).to be_an_instance_of Folio::Patron
      end
    end

    context 'with some needed item details' do
      before do
        allow(mock_client).to receive(:patron_info)
        warden.set_user(user)
      end

      it 'passes through the details' do
        allow(controller).to receive(:item_details).and_return(some: :value)

        controller.patron
        expect(mock_client).to have_received(:patron_info).with('513a9054-5897-11ee-8c99-0242ac120002',
                                                                item_details: { some: :value })
      end
    end

    context 'without a logged in user' do
      it 'is a new instance of the Patron class' do
        expect(controller.patron).to be_nil
      end
    end
  end

  describe '#patron_or_group' do
    let(:patron_info) do
      {
        'user' => { 'active' => false, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end

    before do
      allow(mock_client).to receive_messages(patron_info:)
      warden.set_user(user)
    end

    it 'returns the patron' do
      expect(controller.patron_or_group).to be_an_instance_of Folio::Patron
    end

    it 'returns the group' do
      controller.params[:group] = true
      expect(controller.patron_or_group).to be_an_instance_of Folio::Group
    end
  end
end
