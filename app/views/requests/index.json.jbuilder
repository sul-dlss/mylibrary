# frozen_string_literal: true

json.links do
  json.self requests_url
end

json.data do
  json.array! @requests, partial: 'requests/request', as: :request
end
