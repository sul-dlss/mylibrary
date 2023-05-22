# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SymphonyLegacyClient do
  let(:client) { subject }

  let(:mock_patron) { instance_double(Symphony::Patron, barcode: '1234567890') }

  let(:mock_legacy_client_response) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <LookupPatronInfoResponse
        xmlns="http://schemas.sirsidynix.com/symws/patron"
        xmlns:ns2="http://schemas.sirsidynix.com/symws/common" xmlns:ns3="http://schemas.sirsidynix.com/symws/security">
        <feeInfo>
          <billNumber>5</billNumber>
          <billReasonDescription>Overdue recall</billReasonDescription>
          <amount ns2:currency="USD">21.00</amount>
          <dateBilled>2013-11-25</dateBilled>
          <feePaymentInfo>
            <paymentDate>2013-12-23</paymentDate>
            <paymentAmount ns2:currency="USD">21.00</paymentAmount>
            <paymentTypeDescription>Payment using credit or debit card via MyAccount</paymentTypeDescription>
          </feePaymentInfo>
          <feeItemInfo>
            <itemLibraryID>GREEN</itemLibraryID>
            <title>California : a history</title>
          </feeItemInfo>
        </feeInfo>
        <feeInfo>
          <billNumber>6</billNumber>
          <billReasonDescription>Privileges fee</billReasonDescription>
          <amount ns2:currency="USD">0.01</amount>
          <dateBilled>2013-12-23</dateBilled>
          <feePaymentInfo>
            <paymentDate>2013-12-23</paymentDate>
            <paymentAmount ns2:currency="USD">0.01</paymentAmount>
            <paymentTypeDescription>Fee cancelled</paymentTypeDescription>
          </feePaymentInfo>
        </feeInfo>
       </LookupPatronInfoResponse>'
  end

  describe 'payments' do
    before do
      stub_request(:get, 'https://example.com/symws/rest/patron/lookupPatronInfo?allowedDisplayGroupFees=true&clientID=SymWSTestClient&includeFeeInfo=PAID_FEES_AND_PAYMENTS&sessionToken=1a2b3c4d5e6f7g8h9i0&userID=1234567890')
        .with(
          headers: {
            'Connection' => 'close',
            'Host' => 'example.com'
          }
        )
        .to_return(status: 200, body: mock_legacy_client_response)
    end

    it 'requests payment xml and converts into an array of hashes representing the xml' do
      expect(client.payments('1a2b3c4d5e6f7g8h9i0', mock_patron)).to include(
        hash_including('amount' => '21.00')
      )
    end
  end
end
