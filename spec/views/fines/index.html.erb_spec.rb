# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/index' do
  let(:fine) do
    instance_double(Folio::Account,
                    owed: 3,
                    status: 'A',
                    nice_status: 'Damaged',
                    bib?: true,
                    key: 'abc',
                    bill_date: Date.new,
                    fee: 5,
                    library: 'Best Lib',
                    barcode: '12345',
                    author: 'Author 1',
                    title: 'Title',
                    shelf_key: 'AB 1234',
                    call_number: 'AB 1234',
                    catkey: '12345',
                    patron_key: 'patronkey123',
                    instance_of?: Folio::Account)
  end
  let(:fines) { [fine] }
  let(:checkouts) do
    [Folio::Checkout.new(
      { 'id' => '31d15973-acb6-4a12-92c7-5e2d5f2470ed',
        'item' => { 'title' => 'Mental growth during the first three years' },
        'overdue' => true,
        'details' => { 'feesAndFines' => { 'amountRemainingToPay' => 10 } } }
    )]
  end
  let(:patron) do
    instance_double(Folio::Patron,
                    key: '1',
                    fines: fines,
                    can_pay_fines?: true,
                    requests: [],
                    checkouts: [],
                    remaining_checkouts: nil,
                    barred?: false,
                    status: 'OK',
                    group?: false,
                    sponsor?: false,
                    display_name: 'Shea Sponsor',
                    instance_of?: Folio::Patron)
  end
  let(:group) do
    instance_double(Folio::Group,
                    barred?: false,
                    blocked?: false,
                    status: 'OK',
                    requests: [],
                    checkouts: [],
                    member_name: 'Piper Proxy',
                    fines: [],
                    can_pay_fines?: true,
                    key: 'Sponsor1')
  end
  let(:patron_or_group) { patron }

  context 'when the patron is not in a group' do
    before do
      assign(:fines, fines)
      assign(:checkouts, checkouts)
      without_partial_double_verification do
        allow(view).to receive_messages(patron_or_group: patron, patron: patron)
      end
      allow(fine).to receive(:to_partial_path).and_return('fines/fine')
    end

    it 'shows the fined item author' do
      render
      expect(rendered).to have_text('Author 1')
    end

    it 'shows the Pay button' do
      render
      expect(rendered).to have_text('Pay $3.00 now')
    end

    context 'when the patron has accruing fines' do
      it 'shows the accrued amount' do
        render
        expect(rendered).to have_text('Accruing: $10.00')
      end
    end
  end

  context 'with a sponsor account' do
    before do
      assign(:fines, fines)
      assign(:checkouts, checkouts)
      assign(:patron_or_group, patron_or_group)
      # make the patron a group sponsor
      allow(patron).to receive_messages(sponsor?: true, group: group)
      # allow the is_a? check and return true for Folio::Patron
      allow(patron).to receive(:is_a?).and_return(false)
      allow(patron).to receive(:is_a?).with(Folio::Patron).and_return(true)
      allow(patron_or_group).to receive_messages(group?: true, proxy_borrower?: false)
      without_partial_double_verification do
        allow(view).to receive_messages(patron: patron, patron_or_group: patron_or_group)
      end
      allow(fine).to receive(:to_partial_path).and_return('fines/fine')
    end

    context 'when one of their proxies incurred a fine' do
      it 'displays the proxy fine under the sponsor Self tab' do
        render

        expect(rendered).to include('Borrower:', 'Piper Proxy')
      end

      it 'allows the sponsor to pay the fine' do
        render

        expect(rendered).to have_text('Pay $3.00 now')
      end

      it 'renders the correct message in the group tab' do
        without_partial_double_verification do
          allow(view).to receive(:params).and_return({ group: true })
        end
        render
        expect(rendered).to have_text("Fines incurred by proxy borrowers appear in the list of fines under their sponsor's Self tab.") # rubocop:disable Layout/LineLength
      end
    end

    context 'with a sponsor/self fine' do
      before do
        allow(group).to receive(:member_name).and_return(nil)
      end

      it 'displays the sponsor borrower name' do
        render
        expect(rendered).to include('Borrower:', 'Shea Sponsor')
      end
    end
  end
end
