# frozen_string_literal: true

# Helper module for Requests
module RequestsHelper
  ##
  # Generates the options needed to change a request's location
  def request_location_options(request)
    # TODO: after FOLIO launch remove this conditional wrapper
    if request.is_a?(Folio::Request)
      return options_for_select(
        service_points(request),
        # the second param here pre-selects the current service point in the dropdown
        selected: request.service_point_id
      )
    end

    options_for_select(LibraryLocation.new(request.home_location)
                             .additional_pickup_libraries(request.pickup_library).index_by do |code|
                         Mylibrary::Application.config.library_map[code]
                       end)
  end

  # Generates a list of service point options for a request.
  #
  # @param request [Request] The request object
  # @return [Array<Array<String, String>>] Array of service points in [label, value] format for options_for_select
  def service_points(request)
    return restricted_service_point_options(request) if request.restricted_pickup_service_points.present?

    service_point_options(request)
  end

  private

  # Returns an array of service point options in the format for options_for_select: [[label1, value1], [label2, value2]]
  #
  # @param request [Request] The request object
  # @return [Array<Array<String, String>>] An array of service point options in [label, value] format
  def restricted_service_point_options(request)
    request.restricted_pickup_service_points.map do |item|
      [item['discoveryDisplayName'], item['id']]
    end
  end

  # Returns an array of service point options in the format for options_for_select: [[label1, value1], [label2, value2]]
  #
  # @param request [Request] The request object
  # @return [Array<Array<String, String>>] An array of service point options in [label, value] format
  def service_point_options(request)
    # start with the full list of defaults
    default_service_points = Folio::ServicePoint.default_service_points
    # Add the request's origin service point to the list
    default_service_points << Folio::ServicePoint.find_by_id(request.service_point_id) # rubocop:disable Rails/DynamicFindBy
    # Remove duplicates and nils in case origin was already in the default list or doesn't exit
    # Filter out non-pickup locations
    # Map the service points to the [label, value] format for options_for_select
    default_service_points.compact.uniq(&:id).select { |item| item.pickup_location == true }
                          .map { |item| [item.name, item.id] }
  end
end
