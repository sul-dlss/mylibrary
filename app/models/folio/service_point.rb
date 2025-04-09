# frozen_string_literal: true

module Folio
  class ServicePoint
    attr_reader :id, :code, :name, :pickup_location, :is_default_pickup, :is_default_for_campus

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, code:, name:, pickup_location:, is_default_pickup: false, is_default_for_campus: false)
      @id = id
      @code = code
      @name = name
      @pickup_location = pickup_location
      @is_default_pickup = is_default_pickup
      @is_default_for_campus = is_default_for_campus
    end
    # rubocop:enable Metrics/ParameterLists

    def patron_unpermitted_for_pickup?(patron = nil)
      return false unless patron

      unpermitted_pickup_groups.include?(patron.patron_group_name)
    end

    def unpermitted_pickup_groups
      Settings.service_points[code]&.unpermitted_pickup_groups || []
    end

    class << self
      def all
        @all ||= Folio::Types.get_type('service_points').map { |json| from_dynamic(json) }
      end

      def default_service_points
        all.select { |item| item.is_default_pickup == true }
      end

      def name_by_code(code)
        all.find { |item| item.code == code }&.name
      end

      def find_by_id(id)
        all.find { |item| item.id == id }
      end

      private

      def from_dynamic(json)
        new(id: json.fetch('id'),
            code: json.fetch('code'),
            name: json.fetch('discoveryDisplayName'),
            pickup_location: json.fetch('pickupLocation', false),
            is_default_pickup: json.dig('details', 'isDefaultPickup'),
            is_default_for_campus: json.dig('details', 'isDefaultForCampus'))
      end
    end
  end
end
