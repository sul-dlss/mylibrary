# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Patron do
  subject(:patron) do
    described_class.new(
      {
        key: '1',
        fields: fields
      }.with_indifferent_access
    )
  end

  let(:fields) do
    {
      firstName: 'Student',
      lastName: 'Borrower',
      standing: {
        key: 'DELINQUENT'
      },
      privilegeExpiresDate: nil,
      address1: [
        { 'resource' => '/user/patron/address1',
          'key' => '3',
          'fields' =>
           { 'code' => { 'resource' => '/policy/patronAddress1', 'key' => 'LINE1' },
             'data' => '152B Green Library, 557 Escondido Mall' } },
        { 'resource' => '/user/patron/address1',
          'key' => '4',
          'fields' =>
           { 'code' => { 'resource' => '/policy/patronAddress1', 'key' => 'LINE2' },
             'data' => 'Stanford, CA 94305-6063' } },
        { 'resource' => '/user/patron/address1',
          'key' => '8',
          'fields' =>
           { 'code' => { 'resource' => '/policy/patronAddress1', 'key' => 'EMAIL' },
             'data' => 'superuser1@stanford.edu' } }
      ]
    }
  end

  it 'has a key' do
    expect(patron.key).to eq '1'
  end

  it 'has a first name' do
    expect(patron.first_name).to eq 'Student'
  end

  it 'has a last name' do
    expect(patron.last_name).to eq 'Borrower'
  end

  it 'has an email' do
    expect(patron.email).to eq 'superuser1@stanford.edu'
  end

  it 'has a status' do
    expect(patron.status).to eq 'OK'
  end

  context 'when there is not an email resource in the patron record' do
    before do
      fields[:address1] = []
    end

    it 'does not have an email' do
      expect(patron.email).to be_nil
    end
  end

  describe 'expired_date' do
    it 'returns a date' do
      fields[:privilegeExpiresDate] = '1990-01-01'
      expect(patron.expired_date.strftime('%m/%d/%Y')).to eq '01/01/1990'
    end

    it 'is nil when there is no privilegeExpiresDate' do
      fields[:privilegeExpiresDate] = nil
      expect(patron.expired_date).to be_nil
    end
  end

  describe '#expired?' do
    before do
      fields[:privilegeExpiresDate] = '1990-01-01'
    end

    it 'a patron has expired privileges' do
      expect(patron.expired?).to be true
    end
    it 'a patron has an OK standing but expired status' do
      expect(patron.status).to eq 'Expired'
    end
  end

  describe 'a blocked patron' do
    before do
      fields[:standing]['key'] = 'BARRED'
    end

    it 'shows a blocked status' do
      expect(patron.status).to eq 'Blocked'
    end
    it 'shows more status information if Symphony standing is BARRED' do
      # some wording about needing to contact access services staff
    end
    it 'can have unexpired borrowing privileges' do
      expect(patron.expired?).to be false
    end
  end
end
