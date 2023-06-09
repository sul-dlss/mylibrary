# frozen_string_literal: true

module Folio
  class Library
    MAPPING_FILE = 'config/folio/libraries.json'

    class << self
      include Folio::CodeMapper

      private

      def mapping_file
        MAPPING_FILE
      end
    end
  end
end
