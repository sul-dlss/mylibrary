# frozen_string_literal: true

module Folio
  Library = Data.define(:id, :name, :code) do
    def self.all
      @all ||= Folio::Types.get_type('libraries').map { |json| from_dynamic(json) }
    end

    def self.name_by_code(code)
      all.find { |item| item.code == code }&.name
    end

    def self.find_by_id(id)
      all.find { |item| item.id == id }
    end

    def self.from_dynamic(json)
      new(
        id: json.fetch('id'),
        code: json.fetch('code'),
        name: json['name']
      )
    end
  end
end
