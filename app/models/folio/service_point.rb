# frozen_string_literal: true

module Folio
  class ServicePoint
    MAPPING_FILE = 'config/folio/service-points.json'

    class << self
      include Folio::CodeMapper

      private

      def mapping_file
        MAPPING_FILE
      end

      def uuid_by_code(code)
        all[code]&.id
      end
    end
  end
end
