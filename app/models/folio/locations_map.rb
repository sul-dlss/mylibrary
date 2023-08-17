# frozen_string_literal: true

require 'csv'

module Folio
  class LocationsMap
    include Singleton

    LANE_MAPPING = { 'LANE' => 'LANE-MED' }.freeze

    # @return a tuple of library code and location code
    def self.for(key)
      instance.data[key]
    end

    def data
      @data ||= load_map
    end

    def load_map
      CSV.parse(Rails.root.join('config/folio/locations-map.tsv').read,
                col_sep: "\t").each_with_object({}) do |row, hash|
        library_code = row[1]
        library_code = LANE_MAPPING.fetch(library_code, library_code)

        # SAL3's ONORDER/INPROCESS locations are all mapped so SAL3-STACKS
        next if row[2] == 'SAL3-STACKS' && row[0] != 'STACKS'

        hash[row[2]] ||= [library_code, row[0]]
      end
    end
  end
end
