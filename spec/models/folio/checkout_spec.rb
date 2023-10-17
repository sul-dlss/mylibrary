# frozen_string_literal: true

require 'rails_helper'
require 'models/concerns/folio/folio_record'

RSpec.describe Folio::Checkout do
  subject(:checkout) do
    described_class.new(record.with_indifferent_access, '3684a786-6671-4268-8ed0-9db82ebca60b')
  end

  let(:record) do
    { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
      'item' =>
       { 'title' =>
         'The making of American liberal theology : imagining progressive religion, 1805-1900 / Gary Dorrien.',
         'author' => 'Dorrien, Gary J',
         'instanceId' => '948b80ac-a7fa-5577-87b4-7494ee4c7482',
         'itemId' => '6d9a4f99-d144-51cf-92d7-3edbfc588abe',
         'isbn' => nil,
         'instance' =>
         { 'indexTitle' =>
           'Making of american liberal theology : imagining progressive religion, 1805-1900' },
         'item' =>
         { 'barcode' => '36105110374977',
           'id' => '6d9a4f99-d144-51cf-92d7-3edbfc588abe',
           'status' => { 'date' => '2023-06-02T21:56:43.215+00:00', 'name' => 'Checked out' },
           'effectiveShelvingOrder' => 'BR 3515 D67 42001 11',
           'effectiveCallNumberComponents' => { 'callNumber' => 'BR515 .D67 2001' },
           'effectiveLocation' => { 'code' => 'GRE-STACKS', 'library' => { 'code' => 'GREEN' } },
           'permanentLocation' => { 'code' => 'GRE-STACKS' } } },
      'loanDate' => '2015-12-01T22:27:00.000+00:00',
      'dueDate' => '2023-07-01T06:59:00.000+00:00',
      'overdue' => false,
      'details' =>
       { 'renewalCount' => 2,
         'dueDateChangedByRecall' => nil,
         'dueDateChangedByHold' => nil,
         'proxyUserId' => nil,
         'userId' => 'f1058c51-ba4d-47a5-b919-c71c67b04685',
         'status' => { 'name' => 'Open' },
         'loanPolicy' =>
         { 'name' => '1yearfixed-2renew-14daygrace',
           'description' =>
           'Loan policy for monographs owned by SUL, GSB and Law loaned to faculty.',
           'renewable' => true,
           'renewalsPolicy' => { 'numberAllowed' => 2, 'unlimited' => false },
           'loansPolicy' => { 'period' => nil } } } }
  end

  it_behaves_like 'folio_record', ['3684a786-6671-4268-8ed0-9db82ebca60b']

  it 'has a key' do
    expect(checkout.key).to eq '6f951192-b633-40a0-8112-73a191b55a8a'
  end

  describe '#library' do
    context 'when record is from borrow direct' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
             { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } }
      end

      it { expect(checkout.library).to eq 'BORROW_DIRECT' }
    end

    context 'when record is from ILB' do
      # TODO: SUL-ILB-REPLACE-ME is a placeholder for whatever the new FOLIO code will be
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
              { 'effectiveLocation' => { 'code' => 'SUL-ILB-REPLACE-ME' } } } }
      end

      it { expect(checkout.library).to eq 'ILL' }
    end

    context 'when record is from Green Library' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
             { 'effectiveLocation' => { 'code' => 'GRE-STACKS', 'library' => { 'code' => 'GREEN' } } } } }
      end

      it { expect(checkout.library).to eq 'GREEN' }
    end
  end

  describe '#from_ill?' do
    context 'when record is from borrow direct' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
             { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } }
      end

      it { expect(checkout).to be_from_ill }
    end

    context 'when record is from ILB' do
      # TODO: SUL-ILB-REPLACE-ME is a placeholder for whatever the new FOLIO code will be
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
              { 'effectiveLocation' => { 'code' => 'SUL-ILB-REPLACE-ME' } } } }
      end

      it { expect(checkout).to be_from_ill }
    end

    context 'when record is from Green Library' do
      let(:record) do
        { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
          'item' =>
            { 'item' =>
             { 'effectiveLocation' => { 'code' => 'GRE-STACKS', 'library' => { 'code' => 'GREEN' } } } } }
      end

      it { expect(checkout).not_to be_from_ill }
    end
  end

  describe 'lost?' do
    let(:record) do
      { 'id' => 'dbc35cdf-0fbb-5fbe-8988-b4fa628365c7',
        'item' =>
          { 'item' =>
            { 'status' => { 'name' => status } } } }
    end

    context 'when the checked out item has a lost status' do
      let(:status) { 'Aged to lost' }

      it { expect(checkout.lost?).to be true }
    end

    context 'when the checked out item does not have a lost status' do
      let(:status) { 'Checked out' }

      it { expect(checkout.lost?).to be false }
    end
  end
end
