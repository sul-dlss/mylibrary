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
      profile: {
        key: '',
        fields: {
          chargeLimit: described_class::CHARGE_LIMIT_THRESHOLD
        }
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
      ],
      groupSettings: {
        fields: {
          group: {
            fields: {
              memberList: member_list
            }
          }
        }
      }
    }
  end

  let(:member_list) { [key: '521187'] }

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

  it 'does not have a borrow limit if the number returned in the response exceeds the threshold' do
    fields[:profile][:fields][:chargeLimit] = described_class::CHARGE_LIMIT_THRESHOLD

    expect(patron.borrow_limit).to be_nil
  end

  it 'has no remaining checkouts limit' do
    expect(patron.remaining_checkouts).to be_nil
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
    context 'when expiry date is past' do
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

    context 'when expiry date is in the future' do
      before do
        fields[:privilegeExpiresDate] = '2099-01-01'
      end

      it 'is not expired' do
        expect(patron.expired?).to be false
      end
    end

    context 'when expiry date is nil' do
      before do
        fields[:privilegeExpiresDate] = nil
      end

      it 'is nil' do
        expect(patron.expired?).to be false
      end
    end
  end

  describe 'a blocked patron' do
    before do
      fields[:standing]['key'] = 'BARRED'
    end

    it 'shows a blocked status' do
      expect(patron.status).to eq 'Contact us'
    end
    it 'shows more status information if Symphony standing is BARRED' do
      # some wording about needing to contact access services staff
    end
    it 'can have unexpired borrowing privileges' do
      expect(patron.expired?).to be false
    end
    it 'can be barred' do
      expect(patron.barred?).to be true
    end
  end

  describe 'a fee borrower' do
    before do
      fields[:profile]['key'] = 'MXFEE'
      fields[:profile][:fields][:chargeLimit] = 25
    end

    it 'has a patron type' do
      expect(patron.patron_type).to eq 'Fee borrower'
    end

    it 'is a fee borrower' do
      expect(patron).to be_fee_borrower
    end

    it 'has a borrowing limit' do
      expect(patron.borrow_limit).to eq 25
    end

    context 'with checked out items' do
      before do
        fields[:circRecordList] = [{ fields: {} }]
      end

      it 'has a remaining checkouts' do
        expect(patron.remaining_checkouts).to eq 24
      end
    end
  end

  it 'is not a proxy borrower' do
    expect(patron.proxy_borrower?).to be false
  end

  it 'has no #proxy_borrower_name' do
    expect(patron.proxy_borrower_name).to be_nil
  end

  context 'with a proxy borrower' do
    before do
      fields[:groupSettings] = {
        fields: {
          responsibility: { key: 'PROXY' },
          group: {
            fields: {
              memberList: member_list
            }
          }
        }
      }
      fields[:firstName] = 'Second (P=FirstProxyLN)'
    end

    describe '#proxy_borrower?' do
      it 'is true' do
        expect(patron.proxy_borrower?).to be true
      end
    end

    describe '#proxy_borrower_name' do
      it 'is derived from the first name' do
        expect(patron.proxy_borrower_name).to eq 'Proxy FirstProxyLN'
      end
    end

    describe '#status' do
      context 'when the group is blocked' do
        let(:member_list) do
          [
            { key: '1', fields: {} },
            { key: '2', fields: { standing: { key: 'OK' } } },
            { key: '3', fields: { standing: { key: 'DELINQUENT' } } },
            { key: '411612', fields: { standing: { key: 'BLOCKED' } } }
          ]
        end

        it 'inherits the group status' do
          expect(patron.status).to eq 'Blocked'
        end
      end
    end

    describe '#barred?' do
      context 'when the group is barred' do
        let(:member_list) do
          [
            { key: '1', fields: {} },
            { key: '2', fields: { standing: { key: 'OK' } } },
            { key: '3', fields: { standing: { key: 'DELINQUENT' } } },
            { key: '411612', fields: { standing: { key: 'BARRED' } } }
          ]
        end

        it 'inherits the group barred status' do
          expect(patron).to be_barred
        end
      end
    end
  end

  it 'is not a sponsor' do
    expect(patron.sponsor?).to be false
  end

  context 'with a sponsor' do
    let(:member_list) { [{ key: '521187', fields: {} }] }

    before do
      fields[:groupSettings] = { fields: { responsibility: { key: 'SPONSOR' },
                                           group: { fields: {
                                             memberList: member_list
                                           } } } }
    end

    describe '#sponsor?' do
      it 'is true' do
        expect(patron.sponsor?).to be true
      end
    end

    describe '#group?' do
      context 'when there are group members' do
        let(:member_list) do
          [
            { key: '1', fields: {} },
            { key: '2', fields: {} },
            { key: '3', fields: {} }
          ]
        end

        it 'is true' do
          expect(patron).to be_group
        end
      end

      context 'when the sponsor is the only member of the group' do
        let(:member_list) { [{ key: '1' }] }

        it 'is not a group when only one member' do
          expect(patron).not_to be_group
        end
      end
    end
  end

  context 'with checkouts' do
    before do
      fields[:circRecordList] = [{ key: 1, fields: {} }]
    end

    describe '#checkouts' do
      it 'returns a list of checkouts for the patron' do
        expect(patron.checkouts).to include a_kind_of(Checkout).and(have_attributes(key: 1))
      end
    end
  end

  context 'with fines' do
    before do
      fields[:blockList] = [{ key: 1, fields: {} }]
    end

    describe '#fines' do
      it 'returns a list of fines for the patron' do
        expect(patron.fines).to include a_kind_of(Fine).and(have_attributes(key: 1))
      end
    end
  end

  context 'with requests' do
    before do
      fields[:holdRecordList] = [{ key: 1, fields: {} }]
      allow(BorrowDirectRequests).to receive(:new).and_return(
        instance_double(BorrowDirectRequests, requests: [{ key: 2 }])
      )
    end

    describe '#requests' do
      it 'returns a list of requests for the patron' do
        expect(patron.requests).to include a_kind_of(Request).and(have_attributes(key: 1))
      end

      it 'includes requests that come from the BorrowDirectRequests class' do
        expect(patron.requests.last[:key]).to be 2
      end
    end
  end
end
