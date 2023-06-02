# frozen_string_literal: true

require 'http'

# Calls FOLIO REST endpoints
class FolioClient
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

  # Renew a loan for an item
  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__item__itemid__renew_post
  # @example client.renew_item('cc3d8728-a6b9-45c4-ad0c-432873c3ae47', '123d9cba-85a8-42e0-b130-c82e504c64d6')
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] item_id the UUID of the FOLIO item
  def renew_item(user_id, item_id)
    response = post("/patron/account/#{user_id}/item/#{item_id}/renew")
    check_response(response, title: 'Renew', context: { user_id: user_id, item_id: item_id })
  end

  # API compatibility shim with SymphonyClient
  # @param [String] resource the UUID of the hold in FOLIO
  # @param [String] _item_key the UUID of the FOLIO item; this was required by Symphony.
  # @param [String] patron_key the UUID of the user in FOLIO
  def cancel_hold(resource, _item_key, patron_key)
    cancel_hold_request(patron_key, resource)
  end

  # Cancel a hold request
  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__hold__holdid__cancel_post
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] hold_id the UUID of the FOLIO hold
  def cancel_hold_request(user_id, hold_id)
    # You would think FOLIO could look up this information and merge it itself, but no. You'd
    # also think you could get the /circulation/requests/{id} endpoint data and use that,
    # but the API schema is slightly different and OKAPI complains... so we have to look it
    # up in the patron account data instead.
    request_data = patron_account(user_id)['holds'].find { |h| h['requestId'] == hold_id }
    request_data.merge!('cancellationAdditionalInformation' => 'Canceled by mylibrary',
                        'canceledByUserId' => user_id,
                        'canceledDate' => Time.now.utc.iso8601,
                        'status' => 'Closed - Cancelled')
    response = post("/patron/account/#{user_id}/hold/#{hold_id}/cancel", json: request_data)
    check_response(response, title: 'Cancel', context: { user_id: user_id, hold_id: hold_id })

    response
  end

  # Change hold request date
  # @example client.change_pickup_location(hold_id: '4a64eccd-3e44-4bb0-a0f7-9b4c487abf61',
  #                                        pickup_location_id: 'bd5fd8d9-72f3-4532-b68c-4db88063d16b')
  # @param [String] hold_id the UUID of the FOLIO hold
  # @param [String] pickup_location_id the uuid of the new location
  def change_pickup_location(hold_id:, pickup_location_id:)
    request_data = get_json("/circulation/requests/#{hold_id}")
    request_data['pickupServicePointId'] = 'bd5fd8d9-72f3-4532-b68c-4db88063d16b'
    response = put("/circulation/requests/#{hold_id}", json: request_data)

    check_response(response, title: 'Change pickup location',
                             context: { hold_id: hold_id,
                                        pickup_location_id: pickup_location_id })
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
      check_response(response, title: 'Validate pin', context: { user_id: user_id, pin: pin })
    end
  end

  # Set a pin for a user
  # https://s3.amazonaws.com/foliodocs/api/mod-users/p/patronpin.html#patron_pin_post
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] pin
  def assign_pin(user_id, pin)
    response = post('/patron-pin', json: { id: user_id, pin: pin })
    check_response(response, title: 'Assign pin', context: { user_id: user_id, pin: pin })
  end

  private

  def check_response(response, title:, context:)
    return if response.success?

    context_string = context.map { |k, v| "#{k}: #{v}" }.join(', ')
    raise "#{title} request for #{context_string} was not successful. " \
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
  # @raises [StandardError] if the response was not a 200
  # @return [Hash] the parsed JSON data structure
  def parse_json(response)
    raise response.body unless response.success?
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def escape(str, characters_to_escape: ['"', '*', '?', '^'], escape_character: '\\')
    str.gsub(Regexp.union(characters_to_escape)) { |x| [escape_character, x].join }
  end

  def session_token
    @session_token ||= begin
      response = request('/authn/login', json: { username: @username, password: @password }, method: :post)
      raise response.body unless response.status == 201

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
end
