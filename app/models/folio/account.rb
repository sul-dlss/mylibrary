# frozen_string_literal: true

module Folio
  # Account is FOLIO's model for tracking a sequence of payments/events for a fee/fine
  # Each account has a sequence of actions, stored as FeeFineActions
  # The account payment status is the status of the last action
  # Accounts are analogous to Symphony::Fine when open; Symphony::Payment when closed
  # https://wiki.folio.org/pages/viewpage.action?pageId=73531762
  class Account
    attr_reader :record

    delegate :library_name,
             :library_code,
             :from_ill?,
             :effective_location,
             :permanent_location,
             to: :record_location

    # Statuses that indicate that the patron actually didn't pay anything
    UNPAID_STATUSES = ['Waived fully', 'Cancelled as error'].freeze

    def initialize(record)
      @record = record
    end

    def key
      record['id']
    end

    def patron_key
      record.dig('loan', 'proxyUserId') || record['userId']
    end

    def status
      record.dig('paymentStatus', 'name')
    end

    def nice_status
      record.dig('feeFine', 'feeFineType')
    end

    # dateCreated on the account is often null, so we use the first action date
    def bill_date
      return if record['actions'].none?

      Time.zone.parse(record.dig('actions', 0, 'dateAction'))
    end

    # dateUpdated on the account is often null, so we use the last action date if closed
    def payment_date
      return if record['actions'].none? || !closed?

      Time.zone.parse(record.dig('actions', -1, 'dateAction'))
    end

    def owed
      record['remaining']&.to_d
    end

    def fee
      record['amount']&.to_d
    end

    def bib?
      record['item'].present?
    end

    def catkey
      record.dig('item', 'instance', 'hrid')
    end

    def shelf_key
      record.dig('item', 'effectiveShelvingOrder')
    end

    def author
      record.dig('item', 'instance', 'contributors')&.pluck('name')&.join(', ')
    end

    def title
      record.dig('item', 'instance', 'title')
    end

    def call_number
      record.dig('item', 'holdingsRecord', 'callNumber')
    end

    def barcode
      record.dig('item', 'barcode')
    end

    def to_partial_path
      closed? ? 'payments/payment' : 'fines/fine'
    end

    def closed?
      record.dig('status', 'name') == 'Closed'
    end

    # rubocop:disable Metrics/MethodLength
    def sort_key(key)
      sort_key = case key
                 when :payment_date
                   [payment_sort_key, title, nice_status]
                 when :title
                   [title, payment_sort_key, nice_status]
                 when :fee
                   [fee, payment_sort_key, title, nice_status]
                 when :nice_status
                   [nice_status, payment_sort_key, title]
                 end

      sort_key.join('---')
    end
    # rubocop:enable Metrics/MethodLength

    def payment_sort_key
      return Folio::Request::END_OF_DAYS - payment_date if payment_date

      0
    end

    # 0 if the account was waived/cancelled; full amount otherwise — no partial payments
    # FOLIO treats waived/cancelled as though you paid, so we can't use 'remaining'
    def payment_amount
      UNPAID_STATUSES.include?(status) ? 0 : fee
    end

    private

    def record_location
      @record_location ||= Folio::RecordLocation.new(record['item'] || {})
    end
  end
end
