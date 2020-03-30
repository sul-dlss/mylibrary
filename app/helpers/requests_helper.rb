# frozen_string_literal: true

# Helper module for Requests
module RequestsHelper
  ##
  # Generates the options needed to change a request's location
  def request_location_options(request)
    options_for_select(
      LibraryLocation.new(request.home_location)
        .additional_pickup_libraries(request.pickup_library).index_by do |code|
          Mylibrary::Application.config.library_map[code]
        end
    )
  end
end
