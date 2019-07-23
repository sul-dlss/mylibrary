# frozen_string_literal: true

json.links do
  json.self summaries_url
end

json.data do
  json.type 'patron'
  json.id patron.key
  json.attributes do
    json.status patron.status
    json.expired patron.expired?
    json.email patron.email
    json.patron_type patron.patron_type
    json.first_name patron.first_name
    json.last_name patron.last_name
    json.display_name patron.display_name
    json.borrow_limit patron.borrow_limit
    json.proxy_borrower json.proxy_borrower?
    json.sponsor json.sponsor?

    json.symphony_api_response patron.record if Rails.env.development?
  end
end
