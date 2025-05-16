# frozen_string_literal: true

# Calls FOLIO REST endpoints
class FolioClient
  class IlsError < StandardError; end

  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  delegate :loan_policies, :service_points, to: :folio_graphql_client

  # rubocop:disable Metrics/MethodLength
  def initialize(url: Settings.folio.okapi_url, username: nil, password: nil, tenant: 'sul')
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

  # Overridden so that we don't display password
  def inspect
    "#<#{self.class.name}:#{object_id}  @base_url=\"#{base_url}\">"
  end

  # Login by barcode or university ID, trying barcode first
  # TODO: remove once we're no longer using barcodes for auth
  def login_by_barcode_or_university_id(barcode_or_id, pin)
    login_by_barcode(barcode_or_id, pin) || login_by_university_id(barcode_or_id, pin)
  end

  # Find the user by barcode and validate their PIN, returning the user
  def login_by_barcode(barcode, pin)
    user = find_user_by_barcode(barcode) || find_user_by_legacy_barcode(barcode)

    user if user && validate_patron_pin(user['id'], pin)
  end

  # Find the user by university ID and validate their PIN, returning the user
  def login_by_university_id(university_id, pin)
    user = find_user_by_university_id(university_id)
    user if validate_patron_pin(user['id'], pin)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Find the user by sunetid and return them; auth handled by Shibboleth
  def login_by_sunetid(sunetid)
    find_user_by_sunetid(sunetid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Find a Folio::Patron by barcode or university ID, trying barcode first
  # TODO: remove once we're no longer using barcodes for auth
  def find_patron_by_barcode_or_university_id(barcode_or_id, patron_info: true)
    find_patron_by_barcode(barcode_or_id, patron_info:)
  rescue ActiveRecord::RecordNotFound
    find_patron_by_university_id(barcode_or_id, patron_info:)
  end

  # Find a Folio::Patron by barcode; fetch full patron info if patron_info is true
  def find_patron_by_barcode(barcode, patron_info: true)
    user = find_user_by_barcode(barcode)
    patron_info ? Folio::Patron.find(user['id']) : Folio::Patron.new({ 'user' => user })
  end

  # Find a Folio::Patron by university ID; fetch full patron info if patron_info is true
  def find_patron_by_university_id(university_id, patron_info: true)
    user = find_user_by_university_id(university_id)
    patron_info ? Folio::Patron.find(user['id']) : Folio::Patron.new({ 'user' => user })
  end

  # FOLIO graphql call, compare to #patron_account
  delegate :patron_info, to: :folio_graphql_client

  # FOLIO API call
  def patron_account(patron_key)
    get_json("/patron/account/#{CGI.escape(patron_key)}", params: {
      includeLoans: true,
      includeCharges: true,
      includeHolds: true
    })
  end

  def ping
    session_token.present?
  rescue Faraday::Error, FolioClient::IlsError
    false
  end

  def renew_items(checkouts)
    checkouts.each_with_object(success: [], error: []) do |checkout, status|
      response = renew_item_by_id(checkout.patron_key, checkout.item_id)

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
  # @example client.renew_item_by_id('cc3d8728-a6b9-45c4-ad0c-432873c3ae47', '123d9cba-85a8-42e0-b130-c82e504c64d6')
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] item_id the UUID of the FOLIO item
  def renew_item_by_id(user_id, item_id)
    response = post('/circulation/renew-by-id', json: { itemId: item_id, userId: user_id })
    begin
      check_response(response, title: 'Renew', context: { user_id:, item_id: })
    rescue FolioClient::IlsError => e
      Honeybadger.notify(e)
    end

    response
  end

  # Cancel a request
  # @param [String] request_id the UUID of the FOLIO request
  # @param [String] user_id the UUID of the user in FOLIO
  def cancel_request(request_id, user_id)
    # We formerly used the mod-patron API to cancel requests, but it is
    # unable to cancel title level requests.
    request_data = get_json("/circulation/requests/#{request_id}")

    # Ensure this is the user's request before trying to cancel it
    request_data = {} unless request_data['requesterId'] == user_id || request_data['proxyUserId'] == user_id

    request_data.merge!('cancellationAdditionalInformation' => 'Canceled by mylibrary',
                        'cancelledByUserId' => user_id,
                        'cancelledDate' => Time.now.utc.iso8601,
                        'status' => 'Closed - Cancelled')
    response = put("/circulation/requests/#{request_id}", json: request_data)
    check_response(response, title: 'Cancel', context: { user_id:, request_id: })

    response
  end

  # Change request service point
  # @example client.change_pickup_service_point(request_id: '4a64eccd-3e44-4bb0-a0f7-9b4c487abf61',
  #                                             pickup_location_id: 'bd5fd8d9-72f3-4532-b68c-4db88063d16b')
  # @param [String] request_id the UUID of the FOLIO request
  # @param [String] service_point the UUID of the new service point
  def change_pickup_service_point(request_id, service_point)
    update_request(request_id, { 'pickupServicePointId' => service_point })
  end

  # @example client.change_pickup_expiration(request_id: '4a64eccd-3e44-4bb0-a0f7-9b4c487abf61',
  #                                          expiration: Date.parse('2023-05-18'))
  # @param [String] request_id the UUID of the FOLIO request
  # @param [Date] expiration date of the request
  def change_pickup_expiration(request_id, expiration)
    update_request(request_id, { 'requestExpirationDate' => expiration.to_time.utc.iso8601 })
  end

  # Validate a pin for a user
  # https://s3.amazonaws.com/foliodocs/api/mod-users/p/patronpin.html#patron_pin_verify_post
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] pin
  # @return [Boolean] true when successful
  def validate_patron_pin(user_id, pin)
    response = post('/patron-pin/verify', json: { id: user_id, pin: })
    case response.status
    when 200
      true
    when 422
      false
    else
      check_response(response, title: 'Validate pin', context: { user_id: })
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

  # Mark all of a user's fines (accounts) as having been paid
  # The payment will show as being made from the 'Online' service point
  # rubocop:disable Metrics/MethodLength
  def pay_fines(user_id:, amount:)
    patron = Folio::Patron.find(user_id)
    payload = {
      accountIds: patron.fines.map(&:key),
      paymentMethod: 'Credit card',
      amount:,
      userName: 'libsys_admin',
      transactionInfo: user_id,
      servicePointId: Settings.folio.online_service_point_id,
      notifyPatron: true
    }

    response = post('/accounts-bulk/pay', json: payload)
    check_response(response, title: 'Pay fines', context: payload)
  end
  # rubocop:enable Metrics/MethodLength

  def find_effective_loan_policy(item_type_id:, loan_type_id:, patron_type_id:, location_id:)
    get_json('/circulation/rules/loan-policy',
             params: { item_type_id:,
                       loan_type_id:,
                       patron_type_id:,
                       location_id: }.as_json)
  end

  def libraries
    get_json('/location-units/libraries', params: { limit: 2_147_483_647 }).fetch('loclibs', [])
  end

  def locations
    get_json('/locations', params: { limit: 2_147_483_647 }).fetch('locations', [])
  end

  private

  # Find a user by barcode in FOLIO
  def find_user_by_barcode(barcode)
    get_json('/users', params: { query: CqlQuery.new(barcode:).to_query }).dig('users', 0)
  end

  # Find a user by legacy barcode in FOLIO
  def find_user_by_legacy_barcode(barcode)
    get_json('/users', params: { query: CqlQuery.new('customFields.legacybarcode': barcode).to_query }).dig(
      'users', 0
    )
  end

  # Find a user by university ID (externalSystemId in FOLIO); raise an error if not found
  def find_user_by_university_id(university_id)
    user = get_json('/users', params: { query: CqlQuery.new(externalSystemId: university_id).to_query }).dig('users', 0)
    raise ActiveRecord::RecordNotFound, "User with externalSystemId '#{university_id}' not found" unless user

    user
  end

  # Find a user by sunetid (username in FOLIO); raise an error if not found
  def find_user_by_sunetid(sunetid)
    user = get_json('/users', params: { query: CqlQuery.new(username: sunetid).to_query }).dig('users', 0)
    raise ActiveRecord::RecordNotFound, "User with username '#{sunetid}' not found" unless user

    user
  end

  def update_request(request_id, request_data_updates)
    request_data = get_json("/circulation/requests/#{request_id}")

    request_data.merge!(request_data_updates)
    response = put("/circulation/requests/#{request_id}", json: request_data)
    check_response(response, title: 'Update request',
                             context: { request_id: }.merge(request_data_updates))

    response
  end

  def check_response(response, title:, context:)
    return if response.success?

    context_string = context.map { |k, v| "#{k}: #{v}" }.join(', ')
    raise IlsError, "#{title} request for #{context_string} was not successful. " \
                    "status: #{response.status}, #{response.body}"
  end

  def get(path, **)
    authenticated_request(path, method: :get, **)
  end

  def post(path, **)
    authenticated_request(path, method: :post, **)
  end

  def put(path, **)
    authenticated_request(path, method: :put, **)
  end

  def get_json(path, **)
    parse_json(get(path, **))
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
    request(path, method:, params:, headers: headers.merge('x-okapi-token': session_token), json:)
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
