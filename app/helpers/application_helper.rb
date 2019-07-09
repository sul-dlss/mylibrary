# frozen_string_literal: true

module ApplicationHelper
  def active_page_class(name)
    'active' if controller_name == name
  end
end
