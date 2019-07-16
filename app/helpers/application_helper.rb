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

  # Wrap a link to the SearchWorks record for the given Catkey wrapped in the markup
  # necessary to be aligned with the content in the collapsible list sections
  def detail_link_to_searchworks(catkey)
    content_tag(:div, class: 'row justify-content-center') do
      content_tag(:div, class: 'col-5') do
        link_to Settings.sw.url + catkey, rel: 'noopener', target: '_blank' do
          sul_icon(:'sharp-open_in_new-24px') + 'View in SearchWorks'
        end
      end + content_tag(:div, class: 'col-5') {}
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
