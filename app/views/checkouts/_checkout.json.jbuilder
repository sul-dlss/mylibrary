# frozen_string_literal: true

json.type 'checkout'
json.id checkout.key
json.attributes do
  json.status checkout.status
  json.due_date checkout.due_date
  json.checkout_date checkout.checkout_date
  json.recalled_date checkout.recalled_date
  json.recalled? checkout.recalled?
  json.renewal_date checkout.renewal_date
  json.overdue? checkout.overdue?
  json.library checkout.library
  json.catkey checkout.catkey
  json.title checkout.title
  json.author checkout.author
  json.call_number checkout.call_number
  json.shelf_key checkout.shelf_key

  json.symphony_api_response checkout.record if Rails.env.development?
end
