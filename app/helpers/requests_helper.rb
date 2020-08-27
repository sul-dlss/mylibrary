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

  def check_in_cdl_link(request)
    params = {
      hold_record_key: request.key,
      return_to: controller.request.original_url
    }
    link_to(
      "#{Settings.cdl.url}/cdl/checkin?#{params.to_query}"
    ) do
      safe_join([sul_icon('outline-cancel-24px'), 'Cancel this request'], ' ')
    end
  end

  def cdl_resume_viewing_link(request, text = 'Open viewer')
    link_to(
      text,
      cdl_viewer_url(request),
      class: 'btn btn-primary view-cdl-request',
      target: '_blank',
      rel: 'noopener noreferrer'
    )
  end

  private

  def cdl_viewer_url(request)
    params = {
      url: "#{Settings.purl.url}/#{request.cdl_druid}",
      cdl_hold_record_id: request.key
    }

    "#{Settings.embed.url}/iframe?#{params.to_query}"
  end
end
