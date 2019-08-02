# frozen_string_literal: true

# Class to model Research group information
class Group < Patron
  def patron_type
    'Research group'
  end

  def sponsor
    members.find(&:sponsor?)
  end

  def barred?
    members.any?(&:barred?)
  end

  def status
    Settings.PATRON_STANDING[standing] || ''
  end

  def standing
    possible_standings = Settings.PATRON_STANDING.keys.map(&:to_s)
    members.map(&:standing).min_by { |s| possible_standings.index(s) || Float::INFINITY }
  end

  def checkouts
    @checkouts ||= member_list.flat_map(&:checkouts)
  end

  def fines
    @fines ||= member_list.flat_map(&:fines)
  end

  def requests
    @requests ||= member_list.flat_map(&:requests)
  end

  def member_list
    @member_list ||= members.reject { |patron| patron.key == key || patron.sponsor? }
  end

  def member_list_names
    @member_list_names ||= begin
      member_list.each_with_object({}) { |member, hash| hash[member.key] = member.first_name }
    end
  end

  def member_name(key)
    member_list_names.fetch(key, '').gsub(/(\A\w+\s)\(P=([a-zA-Z]+)\)\z/, '\2')
  end

  def to_partial_path
    'group/group'
  end

  private

  def members
    @members ||= begin
      members = fields.dig('groupSettings', 'fields', 'group', 'fields', 'memberList') || []
      members.map { |member| Patron.new(member) }
    end
  end
end
