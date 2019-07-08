# frozen_string_literal: true

json.array! @summaries, partial: 'summaries/summary', as: :summary
