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

  private

  def library_schedule_path_map
    {
      'EAST-ASIA' => schedule_eal_path,
      'GREEN' => schedule_green_path
    }
  end
end
