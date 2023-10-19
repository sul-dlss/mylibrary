# frozen_string_literal: true

json.type 'checkout'
json.id checkout.key
json.attributes do
  json.status checkout.status
  json.due_date checkout.due_date
  json.days_overdue checkout.days_overdue
  json.checkout_date checkout.checkout_date
  json.recalled_date checkout.recalled_date
  json.recalled? checkout.recalled?
  json.claims_returned_date checkout.claims_returned_date
  json.claimed_returned? checkout.claimed_returned?
  json.renewal_date checkout.renewal_date
  json.renewable checkout.renewable?
  json.renewable_at checkout.renewable_at
  json.renew_from_period checkout.renew_from_period
  json.resource checkout.resource
  json.item_key checkout.item_key
  json.overdue checkout.overdue?
  json.accrued checkout.accrued
  json.days_remaining checkout.days_remaining
  json.library checkout.library
  json.catkey checkout.catkey
  json.title checkout.title
  json.author checkout.author
  json.call_number checkout.call_number
  json.shelf_key checkout.shelf_key
  json.barcode checkout.barcode
  json.short_term_loan checkout.short_term_loan?
  json.effective_location_code checkout.effective_location_code
  json.permanent_location_code checkout.permanent_location_code
  json.lost checkout.lost?

  json.symphony_api_response checkout.record if Rails.env.development?
end
