# frozen_string_literal: true

class ServicePoint
  class << self
    include Enumerable

    def all
      @all ||= JSON.parse(File.read(Rails.root.join('config/service-points.json')), object_class: OpenStruct).index_by(&:id)
    end

    def each(&block)
      return to_enum(__method__) unless block

      all.values.each(&block)
    end

    def find_by_id(id)
      all[id]
    end
  end
end
