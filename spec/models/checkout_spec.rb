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
          currentLocation: { key: 'CHECKEDOUT' },
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

  describe '#days_overdue' do
    context 'when not overdue' do
      before do
        fields['overdue'] = false
      end

      it { expect(checkout.days_overdue).to be 0 }
    end

    context 'when overdue' do
      it 'returns 1 when today is the due date' do
        fields['dueDate'] = Time.zone.now.to_s

        expect(checkout.days_overdue).to be 1
      end

      it 'returns the number of days the item is overdue' do
        fields['dueDate'] = (Time.zone.now - 5.days).to_s

        expect(checkout.days_overdue).to be 6
      end
    end
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
      fields[:recallDueDate] = '2019-08-11T13:59:00-07:00'
    end

    it 'has an updated due date' do
      expect(checkout.due_date.strftime('%m/%d/%Y')).to eq '08/11/2019'
    end

    it 'has a recalled date' do
      expect(checkout.recalled_date.strftime('%m/%d/%Y')).to eq '07/11/2019'
    end

    it 'is recalled' do
      expect(checkout).to be_recalled
    end

    it 'gives a reason why it is not renewable' do
      expect(checkout.non_renewable_reason).to match('user is waiting')
    end

    it 'is not renewable' do
      expect(checkout).not_to be_renewable
    end
  end

  context 'with a record that is renewable' do
    before do
      fields['circulationRule'] = {
        'fields': {
          'renewFromPeriod': 999_999
        }
      }
      fields['unseenRenewalsRemaining'] = 1
    end

    it 'has a renewable? status' do
      expect(checkout).to be_renewable
    end

    describe '#non_renewable_reason' do
      it 'is nil' do
        expect(checkout.non_renewable_reason).to be_nil
      end
    end
  end

  context 'with a record that has unseenRenewalsRemaining as 0' do
    before do
      fields['circulationRule'] = {
        'fields': {
          'renewFromPeriod': 999_999
        }
      }
      fields['unseenRenewalsRemaining'] = 0
    end

    it 'gives a reason why it is not renewable' do
      expect(checkout.non_renewable_reason).to match('No online renewals for this item')
    end

    it 'is not renewable' do
      expect(checkout).not_to be_renewable
    end

    context 'when a record has already been renewed' do
      before do
        fields['renewalCount'] = 10
      end

      it 'gives a more specific reason why it is not renewable' do
        expect(checkout.non_renewable_reason).to match('No online renewals left')
      end

      it 'is not renewable' do
        expect(checkout).not_to be_renewable
      end
    end
  end

  context 'when a record has seenRenewalsRemaining as 0' do
    before do
      fields['circulationRule'] = {
        'fields': {
          'renewFromPeriod': 999_999
        }
      }
      fields['seenRenewalsRemaining'] = 0
    end

    it 'gives a reason why it is not renewable' do
      expect(checkout.non_renewable_reason).to match('No renewals left for this item')
    end

    it 'is not renewable' do
      expect(checkout).not_to be_renewable
    end
  end

  context 'when a record is a reserve item' do
    before do
      fields['circulationRule'] = {
        'fields': {
          'renewFromPeriod': 999_999
        },
        'key': '2HWF-RES'
      }
    end

    it 'gives a reason why it is not renewable' do
      expect(checkout.non_renewable_reason).to match('Renew Reserve items in person')
    end

    it 'is not renewable' do
      expect(checkout).not_to be_renewable
    end
  end

  it 'has a library' do
    expect(checkout.library).to eq 'LAW'
  end

  it 'is not from borrow direct' do
    expect(checkout).not_to be_from_borrow_direct
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

  it 'has a current location' do
    expect(checkout.current_location).to eq 'CHECKEDOUT'
  end

  it 'is not lost' do
    expect(checkout).not_to be_lost
  end

  context 'with a lost item' do
    before do
      fields[:item][:fields][:currentLocation][:key] = 'LOST-ASSUM'
    end

    it 'is lost' do
      expect(checkout).to be_lost
    end

    it 'has an appropriate sort with a higher priority than overdues' do
      expect(checkout.status_sort_key).to eq 1
    end

    it 'gives a reason why it is not renewable' do
      expect(checkout.non_renewable_reason).to match('assumed lost')
    end

    it 'is not renewable' do
      expect(checkout).not_to be_renewable
    end
  end

  it 'is not claimed returned' do
    expect(checkout).not_to be_claimed_returned
  end

  context 'with an item claimed returned' do
    before do
      fields[:claimsReturnedDate] = '2019-07-10T13:59:00-07:00'
    end

    it 'is claimed returned' do
      expect(checkout).to be_claimed_returned
    end

    it 'has a claimed returned date' do
      expect(checkout.claims_returned_date.strftime('%m/%d/%Y')).to eq '07/10/2019'
    end

    it 'has an appropriate sort with a lower priority than overdues' do
      expect(checkout.status_sort_key).to eq 4
    end

    it 'gives a reason why it is not renewable' do
      expect(checkout.non_renewable_reason).to match('review is in process')
    end

    it 'is not renewable' do
      expect(checkout).not_to be_renewable
    end
  end

  it 'does not have a claimed returned date' do
    expect(checkout.claims_returned_date).to be_nil
  end

  context 'when the library is SUL' do
    before { fields[:library] = { key: 'SUL' } }

    it 'represents itself as coming from BorrowDirect' do
      expect(checkout.library).to eq 'BORROW_DIRECT'
    end

    it 'is from borrow direct' do
      expect(checkout).to be_from_borrow_direct
    end
  end
end
