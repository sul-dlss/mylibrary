# frozen_string_literal: true

require 'http'

class FolioGraphqlClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: Settings.folio_graphql.url, username: nil, password: nil, tenant: 'sul')
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

  def get(path, **kwargs)
    request(path, method: :get, **kwargs)
  end

  def post(path, **kwargs)
    request(path, method: :post, **kwargs)
  end

  def get_json(path, **kwargs)
    parse(get(path, **kwargs))
  end

  def post_json(path, **kwargs)
    parse(post(path, **kwargs))
  end

  def patron_info(patron_uuid, loans: true, charges: true, holds: true)
    data = post_json("/", json: {
      query: "query Query($patronId: UUID!) {
        patron(id: $patronId) {
          user {
            username
            barcode
            active
            personal {
              email
              lastName
              firstName
              preferredFirstName
            }
            expirationDate
          }
          id
          holds {
            requestDate
            item {
              instanceId
              title
            }
          }
          charges {
            item {
              instanceId
              itemId
            }
          }
          loans {
            id
            item {
              title
              author
            }
            loanDate
            dueDate
            overdue
          }
        }
      }",
      variables: { patronId: patron_uuid }
    })
    data.dig('data', 'patron')
  end

  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  private

  def parse(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'folio' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'User-Agent': 'FolioGraphqlClient' })
  end
end
