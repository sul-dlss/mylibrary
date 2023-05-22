# frozen_string_literal: true

module Symphony
  # Model for requests in Symphony
  class Request
    include BibRecord

    # A sufficiently large time used to sort nil values last
    # TODO: Update before 2099
    END_OF_DAYS = Time.zone.parse('2099-01-01')

    attr_reader :record

    def initialize(record)
      @record = record
    end

    def to_partial_path
      return 'checkouts/cdl_checkout' if cdl_checkedout?

      'requests/request'
    end

    def key
      record['key']
    end

    def patron_key
      fields['patron']['key']
    end

    def resource
      record['resource']
    end

    def status
      fields['status']
    end

    def ready_for_pickup?
      status == 'BEING_HELD' || cdl_next_up?
    end

    def queue_position
      fields['queuePosition']
    end

    def queue_length
      fields['queueLength']
    end

    def expiration_date
      Time.zone.parse(fields['expirationDate']) if fields['expirationDate']
    end

    def placed_date
      Time.zone.parse(fields['placedDate']) if fields['placedDate']
    end

    def fill_by_date
      Time.zone.parse(fields['fillByDate']) if fields['fillByDate']
    end

    def waitlist_position
      return 'Unknown' if queue_position.nil? && queue_length.nil?

      "#{queue_position} of #{queue_length}"
    end

    def active?
      %w[PLACED BEING_HELD].include?(status)
    end

    def item_call_key
      fields.dig('item', 'fields', 'call', 'key')
    end

    ##
    # Expensive calculation of CDL waitlist
    def cdl_waitlist_position
      return 'Next up ' if cdl_next_up?

      catalog_info = Symphony::CatalogInfo.find(barcode)
      cdl_queue_length = catalog_info.hold_records.count(&:cdl_checkedout?)
      "#{queue_position - cdl_queue_length} of #{queue_length - cdl_queue_length}"
    end

    def pickup_library
      return 'CDL' if cdl?

      fields['pickupLibrary']['key']
    end

    def placed_library
      fields['placedLibrary']['key']
    end

    def library
      if from_borrow_direct?
        Settings.BORROW_DIRECT_CODE
      elsif from_ill?
        Settings.ILL_CODE
      elsif cdl?
        'CDL'
      else
        library_key
      end
    end

    def from_ill?
      (library_key == 'SUL') || from_borrow_direct? || from_ilb?
    end

    # rubocop:disable Metrics/MethodLength
    def sort_key(key)
      sort_key = case key
                 when :library
                   [pickup_library, title, author, shelf_key]
                 when :date
                   [*date_sort_key, title, author, shelf_key]
                 when :title
                   [title, author, shelf_key]
                 when :author
                   [author, title, shelf_key]
                 when :call_number
                   [shelf_key]
                 end

      sort_key.join('---')
    end
    # rubocop:enable Metrics/MethodLength

    def date_sort_key
      [
        (expiration_date || END_OF_DAYS).strftime('%FT%T'),
        (fill_by_date || END_OF_DAYS).strftime('%FT%T')
      ]
    end

    def circ_record
      return unless cdl? && cdl_circ_record_key

      @circ_record ||= begin
        record = Symphony::Checkout.find(cdl_circ_record_key, cdl: true)
        return unless record.checkout_date == cdl_circ_record_checkout_date

        record
      end
    end

    def cdl?
      cdl[0] == 'CDL'
    end

    def cdl_druid
      cdl[1]
    end

    def cdl_circ_record_key
      cdl[2].presence
    end

    def cdl_circ_record_checkout_date
      return if cdl[3].blank?

      Time.zone.at(cdl[3].to_i)
    end

    def cdl_next_up?
      cdl[4] == 'NEXT_UP'
    end

    def cdl_checkedout?
      circ_record.present? if cdl[4] == 'ACTIVE'
    end

    def cdl_expiration_date
      return unless cdl_circ_record_checkout_date

      cdl_circ_record_checkout_date + 30.minutes
    end

    def cdl_loan_period
      return unless cdl?

      (item.dig('itemCategory3', 'key')&.scan(/^CDL-(\d+)H$/)&.flatten&.first&.to_i || 2).hours
    end

    def cdl
      comment.split(';')
    end

    def comment
      fields['comment'].to_s
    end

    private

    def fields
      record['fields']
    end

    def library_key
      item&.dig('library', 'key') || bib['callList']&.first&.dig('fields', 'library', 'key')
    end

    def from_ilb?
      item_type&.starts_with? 'ILB'
    end

    def from_borrow_direct?
      item_type == 'BORROWDIR'
    end

    def item_type
      fields.dig('item', 'fields', 'itemType', 'key')
    end
  end
end
