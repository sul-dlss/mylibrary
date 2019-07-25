# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Group do
  subject(:group) do
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
      expect(group.member_list).to all(be_a(Patron))
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

      it 'doesn\'t include the sponsor' do
        expect(group.member_list.select(&:sponsor?)).to eq []
      end
      it 'doesn\'t include the currently logged in user' do
        expect(group.member_list.map(&:key)).not_to include group.key
      end
      it 'only has member with key 3' do
        expect(group.member_list.map(&:key)).to eq ['3']
      end
    end
  end

  describe '#member_names' do
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

    it 'returns a name give a patron key' do
      expect(group.member_name('411612')).to eq 'Wangchuk'
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
      expect(group.sponsor).to be_an_instance_of(Patron).and(have_attributes(key: '2'))
    end
  end

  describe '#checkouts' do
    let(:member_list) do
      [fields: {
        circRecordList: [
          key: 1,
          fields: {}
        ]
      }]
    end

    it 'has checkouts' do
      expect(group.checkouts).to all(be_a(Checkout))
    end
  end

  describe '#fines' do
    let(:member_list) do
      [fields: {
        blockList: [
          key: 1,
          fields: {}
        ]
      }]
    end

    it 'has fines' do
      expect(group.fines).to all(be_a(Fine))
    end
  end

  describe '#requests' do
    let(:member_list) do
      [fields: {
        holdRecordList: [
          key: 1,
          fields: {}
        ]
      }]
    end

    it 'has fines' do
      expect(group.requests).to all(be_a(Request))
    end
  end
end
