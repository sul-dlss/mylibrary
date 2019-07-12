# frozen_string_literal: true

json.links do
  json.self checkouts_url
end

json.data do
  json.array! @checkouts, partial: 'checkouts/checkout', as: :checkout
end
