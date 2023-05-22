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
    Patron::PATRON_STANDING.fetch(standing, '')
  end

  def standing
    possible_standings = Patron::PATRON_STANDING.keys
    members.map(&:standing).min_by { |s| possible_standings.index(s) || Float::INFINITY }
  end

  def checkouts
    @checkouts ||= member_list.flat_map(&:group_checkouts)
  end

  def fines
    @fines ||= member_list.flat_map(&:group_fines)
  end

  def requests
    @requests ||= member_list.flat_map(&:group_requests)
  end

  def member_list
    @member_list ||= members.reject { |patron| patron.key == key }
  end

  def member_list_names
    @member_list_names ||= member_list.each_with_object({}) do |member, hash|
      hash[member.key] = member.display_name
    end
  end

  def member_name(key)
    member_list_names.fetch(key, '')
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
