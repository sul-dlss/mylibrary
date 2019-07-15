# frozen_string_literal: true

json.type 'request'
json.id request.key
json.attributes do
  json.status request.status
  json.catkey request.catkey
  json.title request.title
  json.author request.author
  json.call_number request.call_number
  json.shelf_key request.shelf_key
  json.queue_position request.queue_position
  json.queue_length request.queue_length

  json.symphony_api_response request.record if Rails.env.development?
end
