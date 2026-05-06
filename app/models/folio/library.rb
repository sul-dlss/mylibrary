# frozen_string_literal: true

module Folio
  Library = Data.define(:id, :name, :code) do
    def self.all
      Folio::Types.libraries
    end

    def self.find_by_code(code)
      Folio::Types.libraries.find_by(code: code)
    end

    def self.find_by_id(id)
      Folio::Types.libraries.find_by(id: id)
    end

    def self.from_dynamic(json)
      new(
        id: json.fetch('id'),
        code: json.fetch('code'),
        name: json.fetch('name')
      )
    end
  end
end
