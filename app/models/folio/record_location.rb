# frozen_string_literal: true

module Folio
  # Determines the presentable library or location for a checkout or request record
  class RecordLocation
    # TODO: Add FOLIO ILL code once we know what it is
    ILL_LOCATION_CODES = %w[SUL-BORROW-DIRECT].freeze

    def initialize(item)
      @item = item
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def library_name
      return effective_location&.discovery_display_name if from_ill?
      return effective_location&.library&.name if treat_temporary_location_as_permanent_location?

      permanent_location&.library&.name
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def library_code
      permanent_location&.library&.code
    end

    def from_ill?
      ILL_LOCATION_CODES.include?(effective_location_code)
    end

    def effective_location
      @effective_location ||= Folio::Location.find_by_code(effective_location_code)
    end

    def permanent_location
      @permanent_location ||= Folio::Location.find_by_code(permanent_location_code)
    end

    private

    def treat_temporary_location_as_permanent_location?
      effective_location&.details&.dig('searchworksTreatTemporaryLocationAsPermanentLocation')
    end

    def effective_location_code
      @item.dig('effectiveLocation', 'code')
    end

    # Fall back to the holding record's effective location.
    # We are no longer guaranteed an item-level permanent location.
    def permanent_location_code
      @item.dig('permanentLocation', 'code') ||
        @item.dig('holdingsRecord', 'effectiveLocation', 'code')
    end
  end
end
