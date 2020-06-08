# frozen_string_literal: true

# Helper for checkouts views
module CheckoutsHelper
  def list_group_item_status_for_checkout(checkout)
    if checkout.recalled?
      'list-group-item-danger'
    elsif checkout.overdue?
      'list-group-item-warning'
    end
  end

  def time_remaining_for_checkout(checkout)
    return pluralize(checkout.days_remaining, 'day') unless checkout.short_term_loan?

    distance_of_time_in_words(Time.zone.now, checkout.due_date)
  end

  # rubocop:disable Metrics/MethodLength
  def render_checkout_status(checkout)
    if checkout.recalled?
      checkout_status_html(css_class: 'text-recalled',
                           icon: 'sharp-error-24px',
                           text: 'Recalled',
                           accrued: checkout.accrued)
    elsif checkout.claimed_returned?
      checkout_status_html(text: 'Processing claim')
    elsif checkout.lost?
      checkout_status_html(css_class: 'text-lost',
                           icon: 'sharp-warning-24px',
                           text: 'Assumed lost',
                           accrued: checkout.accrued)
    elsif checkout.overdue?
      checkout_status_html(css_class: 'text-overdue',
                           icon: 'sharp-warning-24px',
                           text: 'Overdue',
                           accrued: checkout.accrued)
    else
      tag.span 'OK', class: 'd-none d-md-block'
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def checkout_status_html(css_class: nil, icon: nil, text:, accrued: 0)
    tag.span(class: css_class) do
      safe_join([
                  (sul_icon(icon) if icon),
                  text,
                  (number_to_currency(accrued) if accrued.positive?)

                ], ' ')
    end
  end
end
