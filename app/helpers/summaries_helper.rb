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
      enabled_schedule_libraries[library],
      role: 'button',
      class: css_class,
      data: { 'mylibrary-modal': 'trigger' }
    )
  end

  def schedule_once_link_or_dropdown
    return 'Not eligible during current phase of Research Restart Plan' if enabled_schedule_libraries.blank?

    schedulable_libraries = enabled_schedule_libraries.keys

    if schedulable_libraries.one?
      return link_to_schedule_once_visit(
        library: schedulable_libraries.first,
        text: "🗓 Schedule visit to #{library_name(schedulable_libraries.first)}",
        css_class: 'btn btn-primary'
      )
    end

    render 'schedules/schedule_library_visit_dropdown', schedulable_libraries: schedulable_libraries
  end

  def link_to_schedule_pickup(library:, text:, css_class: nil)
    return unless enabled_pickup_libraries[library]

    link_to(
      text,
      enabled_pickup_libraries[library],
      role: 'button',
      class: css_class,
      data: { 'mylibrary-modal': 'trigger' }
    )
  end

  def schedule_pickup_link_or_dropdown
    return if enabled_pickup_libraries.blank?

    pickup_libraries = enabled_pickup_libraries.keys

    if pickup_libraries.one?
      return link_to_schedule_pickup(
        library: pickup_libraries.first,
        text: "🗓 Schedule pickup at #{library_name(pickup_libraries.first)}",
        css_class: 'btn btn-primary'
      )
    end

    render 'schedules/schedule_library_pickup_dropdown', pickup_libraries: pickup_libraries
  end

  private

  def enabled_schedule_libraries
    configured_schedule_libraries = Settings.schedule_access.keys.map(&:to_s)

    library_schedule_path_map.select do |library|
      configured_schedule_libraries.include?(library) && patron_or_group.can_schedule_access?(library)
    end
  end

  def library_schedule_path_map
    {
      'GREEN' => schedule_green_path,
      'EAST-ASIA' => schedule_eal_path
    }
  end

  def enabled_pickup_libraries
    configured_pickup_libraries = Settings.schedule_pickup.keys.map(&:to_s)

    library_pickup_path_map.select do |library|
      configured_pickup_libraries.include?(library) && patron_or_group.can_schedule_pickup?(library)
    end
  end

  def library_pickup_path_map
    {
      'GREEN' => schedule_green_pickup_path,
      'BUSINESS' => schedule_business_pickup_path,
      'EAST-ASIA' => schedule_eal_pickup_path,
      'HOPKINS' => schedule_miller_pickup_path
    }
  end
end
