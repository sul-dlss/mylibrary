# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  let(:mock_client) { instance_double(SymphonyClient) }

  let(:user) do
    { username: 'somesunetid', patron_key: '123' }
  end

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
  end

  describe '#current_user' do
    before do
      warden.set_user(user)
    end

    it 'returns the warden user' do
      expect(controller.current_user).to have_attributes username: 'somesunetid', patron_key: '123'
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
      let(:patron) { Patron.new('fields' => { 'address1' => [], 'standing' => { 'key' => '' } }) }

      before do
        allow(mock_client).to receive(:patron_info).with('123', item_details: {}).and_return(patron)
        warden.set_user(user)
      end

      it 'is a new instance of the Patron class' do
        expect(controller.patron).to be_an_instance_of Patron
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
        expect(mock_client).to have_received(:patron_info).with('123', item_details: { some: :value })
      end
    end

    context 'without a logged in user' do
      it 'is a new instance of the Patron class' do
        expect(controller.patron).to be nil
      end
    end
  end

  describe '#patron_or_group' do
    let(:patron) { Patron.new('fields' => { 'address1' => [], 'standing' => { 'key' => '' } }) }

    before do
      allow(mock_client).to receive(:patron_info).with('123', item_details: {}).and_return(patron)
      warden.set_user(user)
    end

    it 'returns the patron' do
      expect(controller.patron_or_group).to be_an_instance_of Patron
    end

    it 'returns the group' do
      controller.params[:group] = true
      expect(controller.patron_or_group).to be_an_instance_of Group
    end
  end
end
