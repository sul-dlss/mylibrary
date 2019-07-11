# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  subject(:user) { described_class.new(user_attributes) }

  let(:user_attributes) { { username: 'sunetid', patron_key: '123' } }

  it 'has attributes' do
    expect(user).to have_attributes(user_attributes)
  end

  context 'with a shibbolized user' do
    let(:user_attributes) { { shibboleth: true } }

    it 'is marked as a shibboleth-backed user' do
      expect(user).to be_shibboleth
    end
  end
end
