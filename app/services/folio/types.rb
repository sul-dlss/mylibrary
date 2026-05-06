# frozen_string_literal: true

module Folio
  class Types
    class << self
      delegate :loan_policies, :get_type, :libraries, :locations, :service_points, to: :instance
    end

    def self.instance
      @instance ||= new
    end

    attr_reader :cache_dir, :folio_client

    def initialize(cache_dir: Rails.root.join('config/folio'), folio_client: FolioClient.new)
      @cache_dir = cache_dir
      @folio_client = folio_client
    end

    def sync!
      types_of_interest.each do |type|
        file = cache_dir.join("#{type}.json")
        data = folio_client.public_send(type).sort_by { |item| item['id'] }
        File.write(file, JSON.pretty_generate(data))
      end
    end

    def loan_policies
      @loan_policies ||= get_type('loan_policies').index_by { |p| p['id'] }
    end

    def get_type(type)
      raise "Unknown type #{type}" unless types_of_interest.include?(type.to_s)

      file = cache_dir.join("#{type}.json")
      JSON.parse(file.read) if file.exist?
    end

    def libraries
      @libraries ||= TypeStore.new(Folio::Library, get_type('libraries'))
    end

    def locations
      @locations ||= TypeStore.new(Folio::Location, get_type('locations'))
    end

    def service_points
      @service_points ||= TypeStore.new(Folio::ServicePoint, get_type('service_points'))
    end

    private

    def types_of_interest
      %w[
        libraries
        locations
        loan_policies
        service_points
      ]
    end
  end
end
