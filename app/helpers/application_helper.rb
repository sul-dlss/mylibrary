# frozen_string_literal: true

module ApplicationHelper
  def active_page_class(name)
    'active' if controller_name == name
  end

  def list_group_item_status_for_checkout(checkout)
    if checkout.recalled?
      'list-group-item-danger'
    elsif checkout.overdue?
      'list-group-item-warning'
    end
  end

  ##
  # Returns the raw SVG (String) for a SUL Icon located in
  # app/assets/images/icons/*.svg. Caches them so we don't have to look up
  # the svg everytime.
  # @param [String, Symbol] icon_name
  # @return [String]
  def sul_icon(icon_name, options = {})
    Rails.cache.fetch([:sul_icon, icon_name, options]) do
      icon = Icon.new(icon_name, options)
      content_tag(:span, icon.svg.html_safe, icon.options) # rubocop:disable Rails/OutputSafety
    end
  end
end
