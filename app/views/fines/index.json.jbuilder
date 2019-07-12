# frozen_string_literal: true

json.links do
  json.self fines_url
end

json.data do
  json.array! @fines, partial: 'fines/fine', as: :fine
end
