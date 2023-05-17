# frozen_string_literal: true

require 'http'

# Calls FOLIO REST endpoints
class FolioClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: ENV.fetch('OKAPI_URL'), tenant: 'sul')
    uri = URI.parse(url)

    @username = uri.user
    @password = uri.password
    @base_url = uri.dup.tap do |u|
      u.user = nil
      u.password = nil
    end.to_s

    @tenant = tenant
  end

  # Return the FOLIO user_id given a sunetid
  # See https://s3.amazonaws.com/foliodocs/api/mod-users/p/users.html#users__userid__get
  def lookup_user_id(sunetid)
    result = json_response('/users', params: { query: CqlQuery.new(username: sunetid).to_query })
    result.dig('users', 0, 'id')
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

  # Cancel a hold request
  # See https://s3.amazonaws.com/foliodocs/api/mod-patron/p/patron.html#patron_account__id__hold__holdid__cancel_post
  # @param [String] user_id the UUID of the user in FOLIO
  # @param [String] hold_id the UUID of the FOLIO hold
  def cancel_hold_request(user_id, hold_id)
    response = post("/patron/account/#{user_id}/hold/#{hold_id}/cancel")
    check_response(response, title: 'Cancel', context: { user_id: user_id, hold_id: hold_id })
  end

  # Change hold request date
  # @example client.change_pickup_location(hold_id: '4a64eccd-3e44-4bb0-a0f7-9b4c487abf61',
  #                                        pickup_location_id: 'bd5fd8d9-72f3-4532-b68c-4db88063d16b')
  # @param [String] hold_id the UUID of the FOLIO hold
  # @param [String] pickup_location_id the uuid of the new location
  def change_pickup_location(hold_id:, pickup_location_id:)
    request_data = json_response("/circulation/requests/#{hold_id}")
    request_data['pickupServicePointId'] = 'bd5fd8d9-72f3-4532-b68c-4db88063d16b'
    response = put("/circulation/requests/#{hold_id}", json: request_data)

    check_response(response, title: 'Change pickup location',
                             context: { hold_id: hold_id,
                                        pickup_location_id: pickup_location_id })
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

  def json_response(path, **kwargs)
    parse_json(get(path, **kwargs))
  end

  # @param [Faraday::Response] response
  # @raises [StandardError] if the response was not a 200
  # @return [Hash] the parsed JSON data structure
  def parse_json(response)
    raise response unless response.status == 200
    return nil if response.body.empty?

    JSON.parse(response.body)
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
    DEFAULT_HEADERS.merge({ 'X-Okapi-Tenant': @tenant, 'User-Agent': 'SulRequests' })
  end
end
