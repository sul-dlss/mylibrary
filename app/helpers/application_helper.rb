# frozen_string_literal: true

module ApplicationHelper
  def active_page_class(name)
    'active' if controller_name == name
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

  def library_name(code)
    Mylibrary::Application.config.library_map[code] || code
  end

  def render_checkout_status(checkout)
    if checkout.recalled?
      checkout_status_html(css_class: 'text-recalled',
                           icon: 'sharp-error-24px',
                           text: 'Recalled',
                           accrued: checkout.accrued)
    elsif checkout.overdue?
      checkout_status_html(css_class: 'text-overdue',
                           icon: 'sharp-warning-24px',
                           text: 'Overdue',
                           accrued: checkout.accrued)
    end
  end

  private

  def checkout_status_html(css_class:, icon:, text:, accrued: 0)
    content_tag(:span, class: css_class) do
      safe_join([
                  (sul_icon(icon) if icon),
                  text,
                  (number_to_currency(accrued) if accrued.positive?)

                ], ' ')
    end
  end
end
