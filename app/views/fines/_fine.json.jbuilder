# frozen_string_literal: true

json.type 'fine'
json.id fine.key
json.attributes do
  json.status fine.status
  json.library fine.library
  json.catkey fine.catkey
  json.title fine.title
  json.author fine.author
  json.call_number fine.call_number
  json.shelf_key fine.shelf_key
  json.bill_date fine.bill_date
  json.owed fine.owed
  json.fee fine.fee

  json.symphony_api_response fine.record if Rails.env.development?
end
