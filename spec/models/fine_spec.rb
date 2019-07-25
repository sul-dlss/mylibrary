# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fine do
  subject do
    described_class.new({
      key: '1:1',
      fields: fields
    }.with_indifferent_access)
  end

  let(:fine) { subject }
  let(:fields) do
    {
      block: { key: 'DAMAGED' },
      billDate: '2019-07-11',
      owed: {
        amount: '5000.00',
        currencyCode: 'USD'
      },
      item: {
        fields: {
          bib: {
            key: '1184859',
            fields: {
              title: 'The Lego movie videogame [electronic resource]',
              author: 'Cool people made this'
            }
          },
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
    expect(fine.key).to eq '1:1'
  end

  it 'has a sequence' do
    expect(fine.sequence).to eq '1'
  end

  it 'has a status' do
    expect(fine.status).to eq 'DAMAGED'
  end

  it 'has a nice_status' do
    expect(fine.nice_status).to eq 'Damaged item'
  end

  it 'has a title' do
    expect(fine.title).to eq 'The Lego movie videogame [electronic resource]'
  end

  it 'has an author' do
    expect(fine.author).to eq 'Cool people made this'
  end

  it 'has a call number' do
    expect(fine.call_number).to eq 'ZMS 4033'
  end

  it 'has a shelf key' do
    expect(fine.shelf_key).to eq 'ZMS 004033'
  end

  it 'has a catkey' do
    expect(fine.catkey).to eq '1184859'
  end

  it 'has a bill date' do
    expect(fine.bill_date.strftime('%m/%d/%Y')).to eq '07/11/2019'
  end

  it 'has an amount owed' do
    expect(fine.owed).to eq 5000.00
  end

  context 'without a related item' do
    let(:fields) do
      {
        block: { key: 'DAMAGED' },
        billDate: '2019-07-11',
        owed: {
          amount: '5000.00',
          currencyCode: 'USD'
        }
      }
    end

    describe '#bib?' do
      it 'is false' do
        expect(fine.bib?).to eq false
      end
    end

    describe '#title' do
      it 'is nil' do
        expect(fine.title).to eq nil
      end
    end

    describe '#author' do
      it 'is nil' do
        expect(fine.author).to eq nil
      end
    end

    describe '#catkey' do
      it 'is nil' do
        expect(fine.catkey).to eq nil
      end
    end

    describe '#call_number' do
      it 'is nil' do
        expect(fine.call_number).to eq nil
      end
    end

    describe '#shelf_key' do
      it 'is nil' do
        expect(fine.shelf_key).to eq nil
      end
    end
  end
end
