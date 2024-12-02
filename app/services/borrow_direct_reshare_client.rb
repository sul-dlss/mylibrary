# frozen_string_literal: true

require 'http'

class BorrowDirectReshareClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: Settings.borrow_direct_reshare.url,
                 username: Settings.borrow_direct_reshare.username,
                 password: Settings.borrow_direct_reshare.password,
                 tenant: Settings.borrow_direct_reshare.tenant)
    @base_url = url
    @username = username
    @password = password
    @tenant = tenant
  end

  def get(path, **)
    authenticated_request(path, method: :get, **)
  end

  def get_json(path, **)
    parse(get(path, **))
  end

  def requests(university_id)
    get_json('/rs/patronrequests', params:
      { filters: ['state.stage=ACTIVE', 'isRequester=true'],
        match: 'patronIdentifier',
        perPage: 100,
        sort: 'dateCreated;desc',
        term: university_id }) || []
  end

  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  private

  def parse(response)
    return nil if !response || response.body.empty?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Honeybadger.notify(e)
  end

  def session_token
    @session_token ||= begin
      response = request('/authn/login', json: { username: @username, password: @password }, method: :post)
      response ? response['x-okapi-token'] : nil
    end
  end

  def authenticated_request(path, headers: {}, **)
    request(path, headers: headers.merge('x-okapi-token': session_token), **)
  end

  def request(path, headers: {}, method: :get, **)
    HTTP.headers(default_headers.merge(headers))
        .request(method, base_url + path, **)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'X-Okapi-Tenant': @tenant, 'User-Agent': 'ReShareApiClient' })
  end
end
