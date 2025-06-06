# frozen_string_literal: true

module Folio
  # Class to model Research group information
  class Group < Patron
    def patron_type
      'Research group'
    end

    def sponsor
      @sponsor ||= if sponsor?
                     Folio::Patron.new(patron_info)
                   else
                     # if you are a proxy, make a second call to get the sponsor
                     # for now, we only support one sponsor per proxy
                     sponsor_id = user_info.dig('proxiesFor', 0, 'userId')
                     Folio::Patron.find(sponsor_id)
                   end
    end

    delegate :barred?, :blocked?, :patron_group_name, to: :sponsor

    def status
      standing
    end

    def standing
      if barred?
        'Contact us'
      elsif blocked?
        'Blocked'
      else
        'OK'
      end
    end

    def checkouts
      sponsor.group_checkouts || []
    end

    # NOTE: Fines on items borrowed by a proxy/group are associated
    # with the sponsor's individual account.
    def fines
      []
    end

    def requests
      sponsor.group_requests
    end

    def member_list
      @member_list ||= if sponsor?
                         user_info['proxiesOf']
                       elsif proxy_borrower?
                         sponsor.group.member_list
                       end
    end

    def member_list_names
      @member_list_names ||= member_list.each_with_object({}) do |member, hash|
        hash[member['proxyUserId']] =
          "#{member.dig('proxyUser', 'personal', 'firstName')} #{member.dig('proxyUser', 'personal', 'lastName')}"
      end
    end

    def member_name(key)
      member_list_names.fetch(key, nil)
    end

    def to_partial_path
      'group/group'
    end
  end
end
