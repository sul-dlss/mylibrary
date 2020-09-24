# frozen_string_literal: true

##
# Wrap the BorrowDirect::RequestQuery in a class that we
# can inject our patron barcode from (and do error handling)
class BorrowDirectRequests
  attr_reader :patron

  def initialize(patron)
    @patron = patron
  end

  def requests
    request_client.requests('open', true).map { |request| BorrowDirectRequests::Request.new(request) }.select(&:active?)
  rescue BorrowDirect::Error
    []
  end

  private

  def request_client
    @request_client ||= BorrowDirect::RequestQuery.new(patron.barcode)
  end

  ##
  # Wrap the BorrowDirect::RequestQuery::Item in a class
  # so we can give it a similar iterface to Symphony Requests
  class Request < SimpleDelegator
    # Request becomes ON_LOAN once we receive it (and should show as a request ready for pickup/checkout)
    # Request becomes COMPLETED once the uesr returns it
    ACTIVE_REQUEST_STATUSES = %w[
      ENTERED IN_PROCESS SHIPPED
    ].freeze

    def active?
      ACTIVE_REQUEST_STATUSES.include? request_status
    end

    def key
      request_number
    end

    def sort_key(sort)
      case sort
      when :title
        title
      when :date
        [::Request::END_OF_DAYS.strftime('%FT%T'), title].join('---')
      else
        ''
      end
    end

    def pickup_library; end

    def expiration_date; end

    def fill_by_date; end

    def ready_for_pickup?
      false
    end

    def to_partial_path
      'requests/borrow_direct_request'
    end

    def cdl_checkedout?
      false
    end
  end
end
