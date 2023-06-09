# frozen_string_literal: true

module Folio
  module CodeMapper
    include Enumerable

    # rubocop:disable Style/OpenStructUse
    def all
      @all ||= JSON.parse(Rails.root.join(mapping_file).read,
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
