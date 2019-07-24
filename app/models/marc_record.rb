# frozen_string_literal: true

# Model for the a MARC record (formatted as Symphony JSON)
class MarcRecord
  attr_reader :record

  def initialize(record)
    @record = record || {}
  end

  # rubocop:disable all
  def format_main
    return unless leader

    case leader[6]
    when 'a', 't'
      arr = []

      if ['a', 'm'].include? leader[7]
        arr << 'Book'
      end

      if leader[7] == 'c'
        arr << 'Archive/Manuscript'
      end

      arr
    when 'b', 'p'
      'Archive/Manuscript'
    when 'c'
      'Music score'
    when 'd'
      ['Music score', 'Archive/Manuscript']
    when 'e'
      'Map'
    when 'f'
      ['Map', 'Archive/Manuscript']
    when 'g'
      if record_008 && record_008.value[33] =~ /[ |[0-9]fmv]/
        'Video'
      elsif record_008 && record_008.value[33] =~ /[aciklnopst]/
        'Image'
      end
    when 'i'
      'Sound recording'
    when 'j'
      'Music recording'
    when 'k'
      'Image' if record_008 && record_008.value[33] =~ /[ |[0-9]aciklnopst]/
    when 'm'
      if record_008 && record_008.value[26] == 'a'
        'Dataset'
      else
        'Software/Multimedia'
      end
    when 'o' # instructional kit
      'Other'
    when 'r' # 3D object
      'Object'
    end
  end
  # rubocop:enable all

  private

  def leader
    record['leader']
  end

  # rubocop:disable Naming/VariableNumber
  def record_008
    @record_008 ||= begin
      field = record['fields'].find { |f| f['tag'] == '008' } || {}
      subfield = field['subfields'].find { |f| f['code'] == '_' } || {}
      subfield['data']
    end
  end
  # rubocop:enable Naming/VariableNumber
end
