# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  let(:user) do
    { username: 'somesunetid', patron_key: 123 }
  end

  describe '#current_user' do
    before do
      warden.set_user(user)
    end

    it 'returns the warden user' do
      expect(controller.current_user).to have_attributes username: 'somesunetid', patron_key: 123
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
end
