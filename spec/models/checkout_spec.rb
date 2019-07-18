# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Checkout do
  subject do
    described_class.new({
      key: '1',
      fields: fields
    }.with_indifferent_access)
  end

  let(:checkout) { subject }
  let(:fields) do
    {
      estimatedOverdueAmount: {
        amount: '10.00',
        currencyCode: 'USD'
      },
      status: 'ACTIVE',
      overdue: true,
      checkOutDate: '2019-07-08T21:28:00-07:00',
      dueDate: '2019-07-09T23:59:00-07:00',
      library: {
        key: 'LAW'
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
    expect(checkout.key).to eq '1'
  end

  it 'has a status' do
    expect(checkout.status).to eq 'ACTIVE'
  end

  it 'has an overdue state' do
    expect(checkout.overdue?).to be true
  end

  it 'has an accrued' do
    expect(checkout.accrued).to eq 10.00
  end

  describe '#days_remaining' do
    context 'when overdue' do
      before do
        fields['dueDate'] = '2019-07-10T13:59:00-07:00'
        fields['overdue'] = true
      end

      it 'has negative days remaining' do
        expect(checkout.days_remaining).to eq 0
      end
    end

    context 'when overdue' do
      before do
        fields['dueDate'] = (Time.zone.now + 5.days).to_s
        fields['overdue'] = false
      end

      it 'has a positive number of days remaining' do
        expect(checkout.days_remaining).to eq 5
      end
    end
  end

  describe '#short_term_loan?' do
    it 'is true when the loan period type is HOURLY' do
      fields['circulationRule'] = { 'fields' => { 'loanPeriod' => { 'fields' => {
        'periodType' => { 'key' => 'HOURLY' }
      } } } }

      expect(checkout).to be_short_term_loan
    end

    it 'is false when the loan period is any other type (or not defined)' do
      expect(checkout).not_to be_short_term_loan
    end
  end

  it 'has a due date' do
    expect(checkout.due_date.strftime('%m/%d/%Y')).to eq '07/09/2019'
  end

  it 'has a checkout date' do
    expect(checkout.checkout_date.strftime('%m/%d/%Y')).to eq '07/08/2019'
  end

  it 'does not have a renewal date' do
    expect(checkout.renewal_date).to be_nil
  end

  context 'with a record that has been renewed' do
    before do
      fields[:renewalDate] = '2019-07-10T13:59:00-07:00'
    end

    it 'has a renewal date' do
      expect(checkout.renewal_date.strftime('%m/%d/%Y')).to eq '07/10/2019'
    end
  end

  it 'does not have a recalled date' do
    expect(checkout.recalled_date).to be_nil
  end

  it 'is not recalled' do
    expect(checkout).not_to be_recalled
  end

  context 'with a record that has been recalled' do
    before do
      fields[:recalledDate] = '2019-07-11T13:59:00-07:00'
    end

    it 'has a recalled date' do
      expect(checkout.recalled_date.strftime('%m/%d/%Y')).to eq '07/11/2019'
    end

    it 'is recalled' do
      expect(checkout).to be_recalled
    end
  end

  context 'with a record that is renewable' do
    before do
      fields['circulationRule'] = {
        'fields': {
          'renewFromPeriod': 999_999
        }
      }
    end

    it 'has a renewable? status' do
      expect(checkout).to be_renewable
    end
  end

  it 'has a library' do
    expect(checkout.library).to eq 'LAW'
  end

  it 'has a title' do
    expect(checkout.title).to eq 'The Lego movie videogame [electronic resource]'
  end

  it 'has an author' do
    expect(checkout.author).to eq 'Cool people made this'
  end

  it 'has a call number' do
    expect(checkout.call_number).to eq 'ZMS 4033'
  end

  it 'has a shelf key' do
    expect(checkout.shelf_key).to eq 'ZMS 004033'
  end

  it 'has a catkey' do
    expect(checkout.catkey).to eq '1184859'
  end
end
