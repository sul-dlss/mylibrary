# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Symphony::Request do
  subject do
    described_class.new({
      key: '1',
      fields: fields
    }.with_indifferent_access)
  end

  let(:request) { subject }
  let(:fields) do
    {
      status: 'ACTIVE',
      pickupLibrary: { key: 'GREEN' },
      placedLibrary: { key: 'SUL' },
      queuePosition: 3,
      queueLength: 7,
      bib: {
        key: '1184859',
        fields: {
          title: 'The Lego movie videogame [electronic resource]',
          author: 'Cool people made this'
        }
      },
      item: {
        fields: {
          call: {
            fields: {
              dispCallNumber: 'ZMS 4033',
              sortCallNumber: 'ZMS 004033'
            }
          }
        }
      }
    }
  end

  it 'has a key' do
    expect(request.key).to eq '1'
  end

  it 'has a status' do
    expect(request.status).to eq 'ACTIVE'
  end

  it 'has a title' do
    expect(request.title).to eq 'The Lego movie videogame [electronic resource]'
  end

  it 'has an author' do
    expect(request.author).to eq 'Cool people made this'
  end

  it 'has a call number' do
    expect(request.call_number).to eq 'ZMS 4033'
  end

  it 'has a shelf key' do
    expect(request.shelf_key).to eq 'ZMS 004033'
  end

  it 'has a catkey' do
    expect(request.catkey).to eq '1184859'
  end

  it 'has the queue length' do
    expect(request.queue_length).to eq 7
  end

  it 'has the queue position' do
    expect(request.queue_position).to eq 3
  end

  it 'has a placed library' do
    expect(request.placed_library).to eq 'SUL'
  end

  it 'has a pickup library' do
    expect(request.pickup_library).to eq 'GREEN'
  end

  it 'is not from ILL' do
    expect(request).not_to be_from_ill
  end

  context 'without an associated item or bib' do
    before do
      fields[:item] = nil
      fields[:bib] = nil
    end

    it 'has no title' do
      expect(request.title).to be_nil
    end

    it 'has no author' do
      expect(request.author).to be_nil
    end

    it 'has no catkey' do
      expect(request.catkey).to be_nil
    end

    it 'has no call number' do
      expect(request.call_number).to be_nil
    end

    it 'has no shelf key' do
      expect(request.shelf_key).to be_nil
    end
  end

  context 'when a hold is for an on order item' do
    before do
      fields[:item] = nil
      fields[:queuePosition] = nil
      fields[:queueLength] = nil
      fields[:bib][:fields][:callList] = [{ fields: { library: { key: 'GREEN' } } }]
    end

    it 'has an unknown waitlist position' do
      expect(request.waitlist_position).to eq 'Unknown'
    end

    it 'pulls the library from the calllist' do
      expect(request.library).to eq 'GREEN'
    end
  end

  context 'when the item library is SUL' do
    before { fields[:item][:fields][:library] = { key: 'SUL' } }

    it 'represents itself as coming from ILL' do
      expect(request.library).to eq 'ILL'
    end

    it 'is from ILL' do
      expect(request).to be_from_ill
    end
  end

  context 'when the item type is BORROWDIR' do
    before { fields[:item][:fields][:itemType] = { key: 'BORROWDIR' } }

    it 'represents itself as coming from BorrowDirect' do
      expect(request.library).to eq 'BORROW_DIRECT'
    end

    it 'is from ILL' do
      expect(request).to be_from_ill
    end
  end

  context 'when the item type is ILB*' do
    before { fields[:item][:fields][:itemType] = { key: 'ILB12345' } }

    it 'represents itself as coming from ILL' do
      expect(request.library).to eq 'ILL'
    end

    it 'is from ILL' do
      expect(request).to be_from_ill
    end
  end

  context 'when item is a CDL item' do
    before do
      fields[:comment] = 'CDL;druid;123456:1:1;1600892281'
      fields[:bib][:fields][:callList] = [{ fields: { library: { key: 'GREEN' } } }]
    end

    let(:waitlist_hold_records) do
      [
        instance_double(described_class, cdl_checkedout?: true),
        instance_double(described_class, cdl_checkedout?: true),
        instance_double(described_class, cdl_checkedout?: false)
      ]
    end

    it 'is cdl?' do
      expect(request.cdl?).to be true
    end

    it 'has cdl_circ_record_key' do
      expect(request.cdl_circ_record_key).to eq '123456:1:1'
    end

    it 'has circ record checkout date' do
      expect(request.cdl_circ_record_checkout_date.to_i).to eq 1_600_892_281
    end

    it 'cdl_waitlist_position' do
      allow(Symphony::CatalogInfo).to receive(:find).and_return(
        instance_double(Symphony::CatalogInfo, hold_records: waitlist_hold_records)
      )
      expect(request.cdl_waitlist_position).to eq '1 of 5'
    end

    context 'when next up' do
      before do
        fields[:comment] = 'CDL;druid;123456:1:1;1600892281;NEXT_UP'
      end

      it 'is next up' do
        expect(request.cdl_next_up?).to be true
      end
    end

    it 'is cdl_checkedout? if circ record exists' do
      allow(request).to receive(:cdl).and_return([0, 0, 0, 0, 'ACTIVE'])
      allow(request).to receive(:circ_record).and_return({ abc: 123 })
      expect(request.cdl_checkedout?).to be true
    end

    it 'has a druid' do
      expect(request.cdl_druid).to eq 'druid'
    end

    it 'library is CDL' do
      expect(request.library).to eq 'CDL'
    end
  end
end
