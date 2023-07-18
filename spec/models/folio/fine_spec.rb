# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Fine do
  subject(:fine) do
    described_class.new(record.with_indifferent_access)
  end

  let(:record) do
    { 'id' => '4a00ff2c-8a03-4614-8430-e350e8195642',
      'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
      'remaining' => 15,
      'amount' => 25,
      'feeFine' => { 'feeFineType' => 'Manual Replacement Fee' },
      'actions' =>
       [{ 'amountAction' => 25,
          'balance' => 25,
          'id' => 'a0b8d6ae-c7c5-4bda-9405-076d8b21412f',
          'dateAction' => '2023-07-18T00:06:51.538+00:00' },
        { 'amountAction' => 10,
          'balance' => 15,
          'id' => '86c03816-d7de-471e-a99d-90b3b9b4a5f8',
          'dateAction' => '2023-07-18T00:07:19.517+00:00' }],
      'paymentStatus' => { 'name' => 'Paid partially' },
      'item' =>
       { 'effectiveLocation' => { 'library' => { 'name' => 'Art and Architecture' } },
         'instance' => { 'title' => '"Star shining on the mountain',
                         'contributors' => [{ name: 'Author 1' }, { name: 'Author 2' }] },
         'holdingsRecord' => { 'callNumber' => 'MD 7520' } } }
  end

  describe '#key' do
    subject(:key) { fine.key }

    it 'has a key' do
      expect(key).to eq '4a00ff2c-8a03-4614-8430-e350e8195642'
    end
  end

  describe '#author' do
    subject(:author) { fine.author }

    it 'returns the authors' do
      expect(author).to eq 'Author 1, Author 2'
    end
  end

  describe '#patron_key' do
    subject(:patron_key) { fine.patron_key }

    context 'when the fine is not a proxy fine' do
      it { expect(patron_key).to eq 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f' }
    end

    # TODO: in https://github.com/sul-dlss/mylibrary/issues/873
    # context 'when the fine is a proxy fine' do
    #   let(:record) do
    #     { 'details' =>
    #       { 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
    #         'proxy' => { 'firstName' => 'Piper', 'lastName' => 'Proxy', 'barcode' => 'Proxy1' } } }
    #   end

    #   it { expect(fine.patron_key).to eq 'bdfa62a1-758c-4389-ae81-8ddb37860f9b' }
    # end
  end

  context 'with a partially paid fine' do
    it 'has a remaining balance' do
      expect(fine.owed).to eq 15
    end

    it 'displays the full fee amount' do
      expect(fine.fee).to eq 25
    end
  end
end
