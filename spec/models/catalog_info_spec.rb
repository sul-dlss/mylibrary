# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogInfo do
  subject(:catalog_info) { described_class.find('36105123456789') }

  before do
    stub_request(:post, 'https://example.com/symws/user/staff/login')
      .with(body: Settings.symws.login_params.to_h)
      .to_return(body: { sessionToken: 'tokentokentoken' }.to_json)
  end

  describe '#callkey' do
    before do
      stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/36105123456789?.*})
        .to_return(response)
    end

    let(:response) do
      {
        body: '{
          "resource": "/catalog/item",
          "key": "666:2:1",
          "fields": {
            "call": {
              "key": "666:2:1:11"
            }
          }
        }'
      }
    end

    it { expect(catalog_info.callkey).to eq '666:2:1:11' }
  end

  describe '#hold_records' do
    before do
      stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/36105123456789?.*})
        .to_return(response)
    end

    let(:response) do
      {
        body: '{
          "resource": "/catalog/item",
          "key": "666:2:1",
          "fields": {
            "call": {
              "key": "666:2:1:11"
            },
            "bib": {
              "fields": {
                "holdRecordList": [
                  {
                    "fields": {
                      "item": {
                        "fields": {
                          "call": {
                            "key": "666:2:1:11"
                          }
                        }
                      }
                    }
                  },
                  {
                    "fields": {
                      "item": {
                        "fields": {
                          "call": {
                            "key": "666:2:1:11"
                          }
                        }
                      },
                      "status": "PLACED"
                    }
                  },
                  {
                    "fields": {
                      "status": "PLACED"
                    }
                  }
                ]
              }
            }
          }
        }'
      }
    end

    it 'for each holdRecordList item check if its active and if it matches the call key' do
      expect(catalog_info.hold_records.length).to eq 1
    end
  end
end
