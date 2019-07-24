# frozen_string_literal: true

###
#  Class to handle configuration and logic around library codes and labels
#  Adapted from https://github.com/sul-dlss/sul-requests/blob/master/app/models/library_location.rb
###
class LibraryLocation
  def initialize(home_location)
    @home_location = home_location
  end

  def additional_pickup_libraries(current_pickup_library)
    pickup_libraries.except(current_pickup_library)
  end

  # rubocop:disable Style/EmptyCaseCondition
  def pickup_libraries
    case
    when location_specific_pickup_libraries?
      location_specific_pickup_libraries[@home_location]
    when library_specific_pickup_libraries?
      library_specific_pickup_libraries[@home_location]
    else
      config.pickup_libraries
    end
  end
  # rubocop:enable Style/EmptyCaseCondition

  private

  def library_specific_pickup_libraries
    config.library_specific_pickup_libraries
  end

  def location_specific_pickup_libraries
    config.location_specific_pickup_libraries
  end

  def library_specific_pickup_libraries?
    config.library_specific_pickup_libraries.key?(@home_location)
  end

  def location_specific_pickup_libraries?
    config.location_specific_pickup_libraries.key?(@home_location)
  end

  def config
    Mylibrary::Application.config
  end
end
