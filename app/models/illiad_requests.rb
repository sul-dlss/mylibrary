# frozen_string_literal: true

###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadRequests
  def initialize(user_id)
    @user_id = user_id
  end

  def requests
    request_user_transactions.map do |illiad_result|
      IlliadRequests::Request.new(illiad_result)
    end
  rescue StandardError => e
    Honeybadger.notify(e, error_message: "Unable to retrieve ILLIAD transactions with #{e}")
    []
  end

  private

  def request_user_transactions
    url = "#{Settings.sul_illiad}ILLiadWebPlatform/Transaction/UserRequests/#{@user_id}"
    conn = Faraday.new(url: Settings.sul_illiad) do |req|
      req.headers['ApiKey'] = Settings.illiad_api_key
      req.headers['Accept'] = 'application/json; version=1'
      req.adapter Faraday.default_adapter
    end

    response = conn.get(url)
    JSON.parse(response.body)
  end

  class Request
    # illiad_result is a hash with the results from the Illiad Request
    def initialize(illiad_result)
      @illiad_result = illiad_result
    end

    def scan_type?
      @illiad_result['PhotoJournalTitle'].present?
    end

    def key
      @illiad_result['TransactionNumber'].to_s
    end

    # rubocop:disable Metrics/MethodLength
    def sort_key(key)
      sort_key = case key
                 when :library
                   [pickup_library, title, author, call_number]
                 when :date
                   [*date_sort_key, title, author, call_number]
                 when :title
                   [title, author, call_number]
                 when :author
                   [author, title, call_number]
                 when :call_number
                   [call_number]
                 end
      sort_key.join('---')
    end
    # rubocop:enable Metrics/MethodLength

    def date_sort_key
      (expiration_date || Folio::Request::END_OF_DAYS).strftime('%FT%T')
    end

    def title
      scan_type? ? @illiad_result['PhotoJournalTitle'] : @illiad_result['LoanTitle']
    end

    def call_number
      @illiad_result['CallNumber']
    end

    def author
      scan_type? ? @illiad_result['PhotoArticleAuthor'] : @illiad_result['LoanAuthor']
    end

    def placed_date
      Time.zone.parse(@illiad_result['CreationDate'])
    end

    def pickup_library
      @illiad_result['ItemInfo4']
    end

    def expiration_date
      scan_type? ? placed_date + 2.months : Time.zone.parse(@illiad_result['NotWantedAfter'])
    end

    def fill_by_date; end

    def ready_for_pickup?
      ready_for_pickup_status = ['Media Microtext Checkout to Customer',
                                 'Special Collections Checked Out to Customer',
                                 'Customer Notified via E-Mail']
      ready_for_pickup_status.include?(@illiad_result['TransactionStatus'])
    end

    def from_ill?
      true
    end

    def service_point_name
      Mylibrary::Application.config.library_map[pickup_library] || pickup_library
    end

    def waitlist_position; end

    def to_partial_path
      'requests/request'
    end

    def manage_request_link
      "https://sulils.stanford.edu/illiad.dll?Action=10&Form=72&Value=#{key}"
    end
  end
end
