# frozen_string_literal: true

# :nodoc:
module SummariesHelper
  def scheduler_data_param(user_attributes)
    user_attributes.each_with_object([]) do |(k, v), a|
      a << [k, ERB::Util.url_encode(v)].join('=')
    end.join('&')
  end

  # rubocop:disable Layout/LineLength
  def link_to_spec_visit
    link = if patron_or_group.can_schedule_special_collections_visit?
             link_to schedule_spec_path, role: 'button', class: 'btn btn-primary', data: { 'mylibrary-modal': 'trigger' } do
               safe_join([sul_icon(:'visit-spec', classes: 'lg mr-2'), 'Visit Reading Room'], ' ')
             end
           else
             link_to '#', role: 'button', class: 'btn btn-primary disabled' do
               safe_join([sul_icon(:'visit-spec', classes: 'lg mr-2'), 'Visit Reading Room'], ' ')
             end
           end

    link + spec_visit_note
  end
  # rubocop:enable Layout/LineLength

  def spec_visit_note
    return '' if controller_name == 'requests'

    tag.span(class: 'ml-3') do
      if patron_or_group.can_schedule_special_collections_visit?
        'You have items ready for in-library use.'
      else
        'No items waiting.'
      end
    end
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

  # rubocop:disable Layout/LineLength
  def schedule_once_link_or_dropdown
    return if enabled_schedule_libraries.blank?

    schedulable_libraries = enabled_schedule_libraries.keys

    if schedulable_libraries.one?
      return link_to_schedule_once_visit(
        library: schedulable_libraries.first,
        text: safe_join([sul_icon(:'visit-library', classes: 'lg mr-2'), "Enter #{library_name(schedulable_libraries.first)} for research"], ' '),
        css_class: 'btn btn-primary'
      ) + library_entry_note
    end

    render 'schedules/schedule_library_visit_dropdown', schedulable_libraries: schedulable_libraries
  end
  # rubocop:enable Layout/LineLength

  def library_entry_note
    tag.span(class: 'ml-3') do
      safe_join(
        ['You are eligible to enter and remain in the libraries.',
         link_to('See entry requirements.', 'https://library.stanford.edu/status/entry-requirements')], ' '
      )
    end
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

  # rubocop:disable Layout/LineLength
  def schedule_pickup_link_or_dropdown
    return no_pickups_markup if enabled_pickup_libraries.blank?

    pickup_libraries = enabled_pickup_libraries.keys

    if pickup_libraries.one?
      return link_to_schedule_pickup(
        library: pickup_libraries.first,
        text: safe_join([sul_icon(:'request-pickup', classes: 'lg mr-2'), "Pick up requests at #{library_name(pickup_libraries.first)}"], ' '),
        css_class: 'btn btn-primary'
      ) + request_pickup_note
    end

    render 'schedules/schedule_library_pickup_dropdown', pickup_libraries: pickup_libraries
  end
  # rubocop:enable Layout/LineLength

  def no_pickups_markup
    return if controller_name == 'requests'

    link = link_to '#', role: 'button', class: 'btn btn-primary disabled' do
      safe_join([sul_icon(:'request-pickup', classes: 'lg mr-2'), 'Pick up requests'], ' ')
    end

    link + tag.span(class: 'ml-3') { 'No items waiting.' }
  end

  def request_pickup_note
    return '' if controller_name == 'requests'

    tag.span(class: 'ml-3') do
      if enabled_pickup_libraries.keys.one?
        'You have items waiting.'
      else
        safe_join(['You have items waiting at', link_to('multiple libraries.', requests_path)], ' ')
      end
    end
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
      'HOPKINS' => schedule_miller_pickup_path,
      'LAW' => schedule_law_pickup_path
    }
  end
end
