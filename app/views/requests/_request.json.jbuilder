# frozen_string_literal: true

json.type 'request'
json.id request.key
json.attributes do
  json.status request.status
  json.ready_for_pickup request.ready_for_pickup?
  json.catkey request.catkey
  json.title request.title
  json.author request.author
  json.call_number request.call_number
  json.shelf_key request.shelf_key
  json.queue_position request.queue_position
  json.queue_length request.queue_length
  json.expiration_date request.expiration_date
  json.placed_date request.placed_date
  json.fill_by_date request.fill_by_date
  json.pickup_library request.pickup_library
  json.placed_library request.placed_library
  json.library request.library

  json.symphony_api_response request.record if Rails.env.development?
end
