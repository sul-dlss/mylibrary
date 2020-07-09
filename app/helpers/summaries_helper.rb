# frozen_string_literal: true

# :nodoc:
module SummariesHelper
  def scheduler_data_param(user_attributes)
    user_attributes.each_with_object([]) do |(k, v), a|
      a << [k, ERB::Util.url_encode(v)].join('=')
    end.join('&')
  end

  def link_to_schedule_once_visit(library:, text:, css_class: nil)
    link_to(
      text,
      library_schedule_path_map[library],
      role: 'button',
      class: css_class,
      data: { 'mylibrary-modal': 'trigger' }
    )
  end

  def schedule_once_link_or_dropdown
    return 'Not eligible during current phase of Research Restart Plan' if library_schedule_path_map.blank?

    schedulable_libraries = library_schedule_path_map.keys

    if schedulable_libraries.one?
      return link_to_schedule_once_visit(
        library: schedulable_libraries.first,
        text: "🗓 Schedule access to #{library_name(schedulable_libraries.first)}",
        css_class: 'btn btn-primary'
      )
    end

    render 'schedules/schedule_library_visit_dropdown', schedulable_libraries: schedulable_libraries
  end

  def schedule_pickup_link_or_dropdown
    pickup_libraries = library_pickup_path_map.keys
    if pickup_libraries.one?
      return link_to(
        "🗓 Schedule pickup at #{library_name(pickup_libraries.first)}",
        library_pickup_path_map[pickup_libraries.first],
        role: 'button',
        class: 'btn btn-primary',
          data: { 'mylibrary-modal': 'trigger' }
        )
    end
  end

  private

  def library_schedule_path_map
    map = {}
    map['GREEN'] = schedule_green_path if patron_or_group.can_schedule_green_access?
    map['EAST-ASIA'] = schedule_eal_path if patron_or_group.can_schedule_eal_access?

    map
  end

  def library_pickup_path_map
    map = {}
    map['GREEN'] = schedule_pickup_path if patron_or_group.can_schedule_green_pickup?

    map
  end
end
