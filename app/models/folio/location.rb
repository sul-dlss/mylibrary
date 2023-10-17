# frozen_string_literal: true

module Folio
  Location = Data.define(:id, :library, :library_id, :code, :discovery_display_name,
    :name, :primary_service_point_id, :details) do

    def self.all
      @all ||= Folio::Types.get_type('locations').map { |json| from_dynamic(json) }
    end

    def self.discovery_display_name_by_code(code)
      all.find { |item| item.code == code }&.discovery_display_name
    end

    def self.find_by_id(id)
      all.find { |item| item.id == id }
    end

    def self.from_dynamic(json)
      new(
        id: json.fetch('id'),
        library: '', # (Library.new(**json.fetch('library').symbolize_keys) if json['library']),
        library_id: json['libraryId'] || json.dig('library', 'id'),
        code: json.fetch('code'),
        discovery_display_name: json['discoveryDisplayName'] || json['name'] || json.fetch('id'),
        name: json['name'],
        details: json['details'] || {},
        primary_service_point_id: json['primaryServicePoint'] # present in every location in json, but not from Graphql
      )
    end
  end
end
