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

  def today_with_time_or_date(date, short_term: false)
    return l(date, format: :short) unless short_term
    return l(date, format: :short) unless date.today?

    l(date, format: :time_today)
  end

  def time_remaining_for_checkout(checkout)
    return pluralize(checkout.days_remaining, 'day') unless checkout.short_term_loan?

    distance_of_time_in_words(Time.zone.now, checkout.due_date)
  end
end
