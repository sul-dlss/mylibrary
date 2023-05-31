# frozen_string_literal: true

module Folio
  class ServicePoint
    class << self
      include Enumerable

      # rubocop:disable Style/OpenStructUse
      def all
        @all ||= JSON.parse(Rails.root.join('config/service-points.json').read,
                            object_class: OpenStruct).index_by(&:code)
      end
      # rubocop:enable Style/OpenStructUse

      def each(&block)
        return to_enum(__method__) unless block

        all.values.each(&block)
      end

      def find_by(id:)
        all[id]
      end
    end
  end
end
