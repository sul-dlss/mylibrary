# frozen_string_literal: true

# Helper module for Fines
module FinesHelper
  def nice_status_fee_label(status)
    return status if status.ends_with?('fee')

    "#{status} fee"
  end
end
