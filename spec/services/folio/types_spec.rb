# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Types do
  describe '#sync!' do
    subject(:instance) { described_class.new(cache_dir: Pathname.new(tmpdir), folio_client: folio_client) }

    let(:tmpdir) { Dir.mktmpdir }
    let(:folio_client) do
      instance_double(
        FolioClient,
        loan_policies: loan_policies,
        **fake_data
      )
    end
    let(:fake_data) do
      { service_points: ['service_point'] }
    end
    let(:loan_policies) do
      [
        {
          'id' => '5254c6cd-841b-43c8-86e2-15d76470de96',
          'name' => '3hour-norenew-15mingrace'
        }
      ]
    end

    after { FileUtils.remove_entry(tmpdir) }

    it 'makes requests to the FOLIO API and caches that information for future requests' do
      instance.sync!

      fake_data.each do |k, v|
        expect(instance.get_type(k.to_s)).to eq v
      end
    end

    it 'writes the service points data to a file' do
      instance.sync!

      expect(instance.loan_policies).to eq(loan_policies.index_by { |p| p['id'] })
    end
  end
end
