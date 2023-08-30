# frozen_string_literal: true

require 'http'

# Calls FOLIO REST endpoints
class FolioClient
  class IlsError < StandardError; end

  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  # rubocop:disable Metrics/MethodLength
  def initialize(url: Settings.folio.url, username: nil, password: nil, tenant: 'sul')
    uri = URI.parse(url)

    @base_url = url
    @username = username
    @password = password

    if uri.user
      @username ||= uri.user
      @password ||= uri.password
      @base_url = uri.dup.tap do |u|
        u.user = nil
        u.password = nil
      end.to_s
    end

    @tenant = tenant
  end
  # rubocop:enable Metrics/MethodLength

  def login(library_id, pin)
    user_response = get_json('/users', params: { query: CqlQuery.new(barcode: library_id).to_query })
    user = user_response.dig('users', 0)

    return unless user && validate_patron_pin(user['id'], pin)

    user
  end

  def login_by_sunetid(sunetid)
    response = get_json('/users', params: { query: CqlQuery.new(username: sunetid).to_query })
    response.dig('users', 0)
  end

  def user_info(user_id)
    get_json("/users/#{CGI.escape(user_id)}")
  end

  # rubocop:disable Lint/UnusedMethodArgument
  # FOLIO graphql call, compare to #patron_account
  def patron_info(patron_key, item_details: {})
    folio_graphql_client.patron_info(patron_key)
  end

  delegate :service_points, to: :folio_graphql_client

  # FOLIO API call
  def patron_account(patron_key, item_details: {})
    get_json("/patron/account/#{CGI.escape(patron_key)}", params: {
      includeLoans: true,
      includeCharges: true,
      includeHolds: true
    })
  end
  # rubocop:enable Lint/UnusedMethodArgument

  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  # API compatibility shim with SymphonyClient
  # @param [String] resource the UUID of the FOLIO instance record; this was required by Symphony
  # @param [String] item_key the UUID of the FOLIO item
  # @param [String] patron_key the UUID of the user in FOLIO
  def renew_item(_resource, item_key, patron_key)
    renew_item_request(patron_key, item_key)
  end

  def renew_items(checkouts)
    checkouts.each_with_object(success: [], error: []) do |checkout, status|
      response = renew_item(checkout.resource, checkout.item_key, checkout.patron_key)

      case response.status
      when 200
        status[:success] << checkout
      else
        status[:error] << checkout
      end
    end
  end

  # Renew a loan for an item
  # See https://github.com/folio-org/mod-circulation/blob/master/ramls/renew-by-id-request.json
  # @example client.renew_item('cc3d8728-a6b9-45c4-ad0c-432873c3ae47', '123d9cba-85a8-42e0-b130-c82e504c64d6')
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] item_id the UUID of the FOLIO item
  def renew_item_request(user_id, item_id)
    response = post('/circulation/renew-by-id', json: { itemId: item_id, userId: user_id })
    begin
      check_response(response, title: 'Renew', context: { user_id: user_id, item_id: item_id })
    rescue FolioClient::IlsError => e
      Honeybadger.notify(e)
    end

    response
  end

  # API compatibility shim with SymphonyClient
  # @param [String] resource the UUID of the hold in FOLIO
  # @param [String] _item_key the UUID of the FOLIO item; this was required by Symphony.
  # @param [String] patron_key the UUID of the user in FOLIO
  def cancel_hold(resource, _item_key, patron_key)
    cancel_hold_request(patron_key, resource)
  end

  # Cancel a hold request
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] hold_id the UUID of the FOLIO hold
  def cancel_hold_request(user_id, hold_id)
    # We formerly used the mod-patron API to cancel hold requests, but it is
    # unable to cancel title level hold requests.
    request_data = get_json("/circulation/requests/#{hold_id}")

    # Ensure this is the user's request before trying to cancel it
    request_data = {} unless request_data['requesterId'] == user_id

    request_data.merge!('cancellationAdditionalInformation' => 'Canceled by mylibrary',
                        'cancelledByUserId' => user_id,
                        'cancelledDate' => Time.now.utc.iso8601,
                        'status' => 'Closed - Cancelled')
    response = put("/circulation/requests/#{hold_id}", json: request_data)
    check_response(response, title: 'Cancel', context: { user_id: user_id, hold_id: hold_id })

    response
  end

  # TODO: after FOLIO launch rename this method to reflect service point terminology (maybe change_pickup_service_point)
  #
  # Change hold request service point
  # @example client.change_pickup_library(hold_id: '4a64eccd-3e44-4bb0-a0f7-9b4c487abf61',
  #                                        pickup_location_id: 'bd5fd8d9-72f3-4532-b68c-4db88063d16b')
  # @param [String] id the UUID of the FOLIO hold
  # @param [String] service_point the UUID of the new service point
  def change_pickup_library(id, service_point)
    request_data = get_json("/circulation/requests/#{id}")
    request_data['pickupServicePointId'] = service_point
    response = put("/circulation/requests/#{id}", json: request_data)
    check_response(response, title: 'Change pickup location',
                             context: { id: id,
                                        service_point: service_point })
    response
  end

  # @example client.change_pickup_expiration(hold_id: '4a64eccd-3e44-4bb0-a0f7-9b4c487abf61',
  #                                        expiration: Date.parse('2023-05-18'))
  # @param [String] hold_id the UUID of the FOLIO hold
  # @param [Date] expiration the hold request
  def change_pickup_expiration(hold_id:, expiration:)
    request_data = get_json("/circulation/requests/#{hold_id}")
    request_data['requestExpirationDate'] = expiration.to_time.utc.iso8601
    response = put("/circulation/requests/#{hold_id}", json: request_data)

    check_response(response, title: 'Change pickup expiration',
                             context: { hold_id: hold_id,
                                        expiration: expiration })
  end

  # Validate a pin for a user
  # https://s3.amazonaws.com/foliodocs/api/mod-users/p/patronpin.html#patron_pin_verify_post
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] pin
  # @return [Boolean] true when successful
  def validate_patron_pin(user_id, pin)
    response = post('/patron-pin/verify', json: { id: user_id, pin: pin })
    case response.status
    when 200
      true
    when 422
      false
    else
      check_response(response, title: 'Validate pin', context: { user_id: user_id })
    end
  end

  # Assign a patron a new PIN using a token that identifies them
  # https://s3.amazonaws.com/foliodocs/api/mod-users/p/patronpin.html#patron_pin_post
  # @param [String] token the reset token
  # @param [String] new_pin the new PIN to assign
  def change_pin(token, new_pin)
    patron_key = crypt.decrypt_and_verify(token)
    # expired tokens evaluate to nil; we want to raise an error instead
    raise ActiveSupport::MessageEncryptor::InvalidMessage unless patron_key

    response = post('/patron-pin', json: { id: patron_key, pin: new_pin })
    check_response(response, title: 'Assign pin', context: { user_id: patron_key })
  end

  # Look up a patron by barcode and return a Patron object
  # If 'patron_info' is false, don't run the full patron info GraphQL query
  def find_patron_by_barcode(barcode, patron_info: true)
    response = get_json('/users', params: { query: CqlQuery.new(barcode: barcode).to_query })
    user = response.dig('users', 0)
    raise ActiveRecord::RecordNotFound, "User with barcode #{barcode} not found" unless user

    patron_info ? Folio::Patron.find(user['id']) : Folio::Patron.new({ 'user' => user })
  end

  # Mark all of a user's fines (accounts) as having been paid
  # The payment will show as being made from the 'Online' service point
  # rubocop:disable Metrics/MethodLength
  def pay_fines(user:, amount:, session_id:)
    patron = find_patron_by_barcode(user)
    payload = {
      accountIds: patron.fines.map(&:key),
      paymentMethod: 'Credit card',
      amount: amount,
      userName: 'libsys_admin',
      transactionInfo: session_id,
      servicePointId: Settings.folio.online_service_point_id,
      notifyPatron: true
    }

    response = post('/accounts-bulk/pay', json: payload)
    check_response(response, title: 'Pay fines', context: payload)
  end
  # rubocop:enable Metrics/MethodLength

  private

  def check_response(response, title:, context:)
    return if response.success?

    context_string = context.map { |k, v| "#{k}: #{v}" }.join(', ')
    raise IlsError, "#{title} request for #{context_string} was not successful. " \
                    "status: #{response.status}, #{response.body}"
  end

  def get(path, **kwargs)
    authenticated_request(path, method: :get, **kwargs)
  end

  def post(path, **kwargs)
    authenticated_request(path, method: :post, **kwargs)
  end

  def put(path, **kwargs)
    authenticated_request(path, method: :put, **kwargs)
  end

  def get_json(path, **kwargs)
    parse_json(get(path, **kwargs))
  end

  def folio_graphql_client
    @folio_graphql_client ||= FolioGraphqlClient.new
  end

  # @param [Faraday::Response] response
  # @raises [IlsError] if the response was not successful
  # @return [Hash] the parsed JSON data structure
  def parse_json(response)
    raise IlsError, response.body unless response.success?
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def escape(str, characters_to_escape: ['"', '*', '?', '^'], escape_character: '\\')
    str.gsub(Regexp.union(characters_to_escape)) { |x| [escape_character, x].join }
  end

  def session_token
    @session_token ||= begin
      response = request('/authn/login', json: { username: @username, password: @password }, method: :post)
      raise IlsError, response.body unless response.status == 201

      response['x-okapi-token']
    end
  end

  def authenticated_request(path, method:, params: nil, headers: {}, json: nil)
    request(path, method: method, params: params, headers: headers.merge('x-okapi-token': session_token), json: json)
  end

  def request(path, method:, headers: nil, params: nil, json: nil)
    connection.send(method, path, params, headers) do |req|
      req.body = json.to_json if json
    end
  end

  def connection
    @connection ||= Faraday.new(base_url) do |builder|
      builder.request :retry, max: 4, interval: 1, backoff_factor: 2
      default_headers.each do |k, v|
        builder.headers[k] = v
      end
    end
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-Okapi-Tenant': @tenant, 'User-Agent': 'FolioApiClient' })
  end

  # Encryptor/decryptor for the token used in the PIN reset process
  def crypt
    @crypt ||= begin
      keygen = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
      key = keygen.generate_key('patron pin reset token', ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
