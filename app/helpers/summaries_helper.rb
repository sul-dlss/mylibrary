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
    return unless Settings.schedule_spec

    if patron_or_group.can_schedule_special_collections_visit?
      link_to schedule_visit_path('SPEC-COLL'), role: 'button', class: 'btn btn-primary', data: { 'mylibrary-modal': 'trigger' } do
        safe_join([sul_icon(:'visit-spec', classes: 'lg mr-2'), 'Visit Reading Room'], ' ')
      end
    else
      link_to '#', role: 'button', class: 'btn btn-primary disabled' do
        safe_join([sul_icon(:'visit-spec', classes: 'lg mr-2'), 'Visit Reading Room'], ' ')
      end
    end
  end
  # rubocop:enable Layout/LineLength

  def spec_visit_note
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
      schedule_visit_path(library),
      role: 'button',
      class: css_class,
      data: { 'mylibrary-modal': 'trigger' }
    )
  end

  # rubocop:disable Layout/LineLength
  def schedule_once_link_or_dropdown
    schedulable_libraries = enabled_schedule_libraries

    return if schedulable_libraries.blank?

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
    return unless enabled_pickup_libraries.include? library

    link_to(
      text,
      schedule_pickup_path(library),
      role: 'button',
      class: css_class,
      data: { 'mylibrary-modal': 'trigger' }
    )
  end

  # rubocop:disable Layout/LineLength
  def schedule_pickup_link_or_dropdown
    pickup_libraries = enabled_pickup_libraries

    return no_pickups_markup if pickup_libraries.blank?

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

    post_text = safe_join(['No items waiting that require an appointment.', link_to_pickup_requests], ' ')

    link + tag.span(class: 'ml-3') { post_text }
  end

  def request_pickup_note
    return '' if controller_name == 'requests'

    tag.span(class: 'ml-3') do
      if enabled_pickup_libraries.one?
        link_to('You have items waiting.', requests_path)
      else
        safe_join(['You have items waiting at', link_to('multiple libraries.', requests_path)], ' ')
      end
    end
  end

  private

  def link_to_pickup_requests
    return unless (count = patron_or_group.requests.count(&:ready_for_pickup?)).positive?

    link_to("#{pluralize(count, 'request')} ready for pick up.", requests_path)
  end

  def enabled_schedule_libraries
    configured_schedule_libraries = Settings.schedule_access.keys.map(&:to_s)

    configured_schedule_libraries.select do |library|
      patron_or_group.can_schedule_access?(library)
    end
  end

  def enabled_pickup_libraries
    configured_pickup_libraries = Settings.schedule_pickup.keys.map(&:to_s)

    configured_pickup_libraries.select do |library|
      patron_or_group.can_schedule_pickup?(library)
    end
  end
end
