# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Symphony::Group do
  subject(:group) do
    described_class.new(
      {
        key: '1',
        fields:
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
      groupSettings: {
        fields: {
          responsibility: { key: 'PROXY' },
          group: {
            fields: {
              memberList: member_list
            }
          }
        }
      }
    }
  end

  let(:member_list) { [{ key: '521187', fields: {} }] }

  describe '#member_list' do
    it 'is an array of patrons' do
      expect(group.member_list).to all(be_a(Symphony::Patron))
    end

    it 'has a patron with a key' do
      expect(group.member_list.first.key).to eq '521187'
    end

    describe 'filtering' do
      let(:member_list) do
        [
          { key: '1', fields: {} },
          { key: '2', fields: { groupSettings: {
            fields: {
              responsibility: {
                key: 'SPONSOR'
              }
            }
          } } },
          { key: '3', fields: {} }
        ]
      end

      it 'doesn\'t include the currently logged in user' do
        expect(group.member_list.map(&:key)).not_to include group.key
      end

      it 'has all the other members' do
        expect(group.member_list.map(&:key)).to eq %w[2 3]
      end
    end
  end

  describe '#member_names' do
    let(:member_list) do
      [
        { key: '2', fields: {
          firstName: 'Faculty',
          lastName: 'Sponsor',
          groupSettings: {
            fields: { responsibility: { key: 'SPONSOR' } }
          }
        } },
        { key: '411612', fields: {
          firstName: 'Mark (P=Wangchuk)',
          groupSettings: {
            fields: { responsibility: { key: 'PROXY' } }
          }
        } }
      ]
    end

    it 'returns a name give a patron key' do
      expect(group.member_name('411612')).to eq 'Wangchuk'
    end

    it 'returns the display name for the group sponsor' do
      expect(group.member_name('2')).to eq 'Faculty Sponsor'
    end
  end

  describe '#sponsor' do
    let(:member_list) do
      [
        { key: '1', fields: {} },
        { key: '2', fields: { groupSettings: {
          fields: { responsibility: { key: 'SPONSOR' } }
        } } },
        { key: '3', fields: {} },
        { key: '411612', fields: { firstName: 'Mark (P=Wangchuk)' } }
      ]
    end

    it 'returns the group sponsor' do
      expect(group.sponsor).to be_an_instance_of(Symphony::Patron).and(have_attributes(key: '2'))
    end
  end

  describe '#barred?' do
    context 'when a member of the group is barred' do
      let(:member_list) do
        [
          { key: '1', fields: {} },
          { key: '2', fields: { groupSettings: {
            fields: { responsibility: { key: 'SPONSOR' } }
          } } },
          { key: '3', fields: { standing: { key: 'BARRED' } } },
          { key: '411612', fields: { firstName: 'Mark (P=Wangchuk)' } }
        ]
      end

      it 'is barred' do
        expect(group).to be_barred
      end
    end

    context 'with all members in good standing' do
      it 'is not barred' do
        expect(group).not_to be_barred
      end
    end
  end

  describe '#standing' do
    let(:member_list) do
      [
        { key: '1', fields: {} },
        { key: '2', fields: { standing: { key: 'OK' } } },
        { key: '3', fields: { standing: { key: 'BARRED' } } },
        { key: '411612', fields: { standing: { key: 'OK' } } }
      ]
    end

    it 'is the worst possible standing of the members of the group' do
      expect(group.standing).to eq 'BARRED'
    end
  end

  describe '#status' do
    let(:member_list) do
      [
        { key: '1', fields: {} },
        { key: '2', fields: { standing: { key: 'OK' } } },
        { key: '3', fields: { standing: { key: 'DELINQUENT' } } },
        { key: '411612', fields: { standing: { key: 'BLOCKED' } } }
      ]
    end

    it 'is the worst possible status of the members of the group' do
      expect(group.status).to eq 'Blocked'
    end
  end

  describe '#checkouts' do
    let(:member_list) do
      [{ fields: {
        circRecordList: [
          { key: 1,
            fields: {} }
        ]
      } }]
    end

    it 'has checkouts' do
      expect(group.checkouts).to all(be_a(Symphony::Checkout))
    end
  end

  describe '#fines' do
    let(:member_list) do
      [{ fields: {
        blockList: [
          { key: '1',
            fields: {} }
        ]
      } }]
    end

    it 'has fines' do
      expect(group.fines).to all(be_a(Symphony::Fine))
    end
  end

  describe '#requests' do
    let(:member_list) do
      [{ fields: {
        holdRecordList: [
          { key: 1,
            fields: {} }
        ]
      } }]
    end

    before do
      allow(BorrowDirectRequests).to receive(:new).and_return(
        instance_double(BorrowDirectRequests, requests: [
                          instance_double(BorrowDirectRequests::Request, key: 2)
                        ])
      )
    end

    it 'has requests from symphony' do
      expect(group.requests.first).to be_a(Symphony::Request)
    end

    it 'has requests from BorrowDirect' do
      expect(group.requests.last).to have_attributes(key: 2)
    end
  end
end
