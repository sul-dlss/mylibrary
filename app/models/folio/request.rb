# frozen_string_literal: true

module Folio
  # ? FOLIO: Request = "Hold" in Folio - consider renaming for clarity
  class Request
    include Folio::FolioRecord

    attr_reader :record

    # A sufficiently large time used to sort nil values last
    # TODO: Update before 2099
    END_OF_DAYS = Time.zone.parse('2099-01-01')

    def initialize(record)
      @record = record
    end

    def to_partial_path
      return 'checkouts/cdl_checkout' if cdl_checkedout?

      'requests/request'
    end

    def key
      record['requestId']
    end

    def patron_key
      record.dig('details', 'proxyUserId') || record.dig('details', 'requesterId')
    end

    # @return [Boolean] Returns true if the proxyUserId exists
    def proxy_request?
      record.dig('details', 'proxyUserId').present?
    end

    def resource
      key
    end

    def status
      record['status']
    end

    def ready_for_pickup?
      status == 'Open___Awaiting_pickup'
    end

    def queue_position
      record['queuePosition']
    end

    def queue_length
      record['queueTotalLength']
    end

    def expiration_date
      Time.zone.parse(record.dig('details', 'holdShelfExpirationDate')) if record.dig('details',
                                                                                      'holdShelfExpirationDate')
    end

    def placed_date
      Time.zone.parse(record['requestDate']) if record['requestDate']
    end

    def fill_by_date
      Time.zone.parse(record['expirationDate']) if record['expirationDate']
    end

    def waitlist_position
      return 'Unknown' if queue_position.nil? && queue_length.nil?

      "#{queue_position} of #{queue_length}"
    end

    def active?
      status.start_with?('Open')
    end

    def item_call_key
      record.dig('item', 'item', 'effectiveCallNumberComponents', 'callNumber')
    end

    ##
    # Expensive calculation of CDL waitlist
    def cdl_waitlist_position
      return 'Next up ' if cdl_next_up?

      catalog_info = CatalogInfo.find(barcode)
      cdl_queue_length = catalog_info.hold_records.count(&:cdl_checkedout?)
      "#{queue_position - cdl_queue_length} of #{queue_length - cdl_queue_length}"
    end

    def pickup_library
      return 'CDL' if cdl?

      record.dig('pickupLocation', 'code')
    end

    # this is only used in JSON responses; maybe we can remove it?
    def placed_library
      library_key
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
        record = Checkout.find(cdl_circ_record_key, cdl: true)
        return unless record.checkout_date == cdl_circ_record_checkout_date

        record
      end
    end

    # TODO: after FOLIO launch revisit CDL logic. Currently we've disabled it.
    def cdl?
      false
    end

    def cdl_loan_period
      nil
    end

    def cdl_checkedout?
      false
    end

    def cdl_expiration_date
      nil
    end

    private

    def library_key
      record.dig('item', 'item', 'effectiveLocation', 'library', 'code')
    end

    def from_ilb?
      # TODO
      nil
    end

    def from_borrow_direct?
      location_code == 'SUL-BORROW-DIRECT'
    end

    def location_code
      record.dig('item', 'item', 'effectiveLocation', 'code')
    end

    def item_type
      # TODO
      nil
    end
  end
end
