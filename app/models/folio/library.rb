# frozen_string_literal: true

module Folio
  Library = Data.define(:id, :name, :code) do
    def self.from_dynamic(json)
      new(
        id: json.fetch('id'),
        code: json.fetch('code'),
        name: json.fetch('name')
      )
    end
  end
end
