# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Checkout do
  subject(:checkout) do
    described_class.new(record.with_indifferent_access)
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

  it 'has a key' do
    expect(checkout.key).to eq '6f951192-b633-40a0-8112-73a191b55a8a'
  end
end
