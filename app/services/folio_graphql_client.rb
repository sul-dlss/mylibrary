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

  def patron_info(patron_uuid)
    data = post_json('/', json: {
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
            externalSystemId
            patronGroup {
              group
              desc
            }
            blocks {
              message
            }
            manualBlocks {
              desc
            }
          }
          id
          holds {
            requestDate
            item {
              instanceId
              title
              itemId

              item {
                circulationNotes {
                  id
                  noteType
                  note
                  source {
                    personal {
                      lastName
                    }
                    id
                  }
                  date
                  staffOnly
                }
                effectiveShelvingOrder
                effectiveCallNumberComponents {
                  callNumber
                }
                effectiveLocation {
                  library {
                    code
                  }
                }
              }
              author
              instance {
                hrid
              }
              isbn
            }
            requestId
            status
            expirationDate
            pickupLocationId
            pickupLocation {
              code
            }
            queuePosition
            cancellationReasonId
            canceledByUserId
            cancellationAdditionalInformation
            canceledDate
            patronComments
          }
          accounts {
            item {
              instance {
                id
              }
              id
              effectiveShelvingOrder
              effectiveCallNumberComponents {
                callNumber
              }
              permanentLocation {
                name
              }
            }
            amount
            dateCreated
            feeFineId
            feeFineType
            feeFine {
              id
              automatic
              feeFineType
              defaultAmount
              chargeNoticeId
              actionNoticeId
              ownerId
              metadata {
                createdDate
                createdByUserId
                createdByUsername
                updatedDate
                updatedByUserId
                updatedByUsername
              }
            }
            metadata {
              createdDate
            }
            paymentStatus {
              name
            }
          }
          loans {
            id
            item {
              title
              author
              instanceId
              itemId
              isbn
              instance {
                indexTitle
              }
              item {
                barcode
                id
                status {
                  date
                  name
                }
                effectiveShelvingOrder
                effectiveCallNumberComponents {
                  callNumber
                }
                effectiveLocation {
                  code
                  library {
                    code
                  }
                }
                permanentLocation {
                  code
                }
              }
            }
            loanDate
            dueDate
            overdue
            details {
              renewalCount
              dueDateChangedByRecall
              dueDateChangedByHold
              proxyUserId
              userId
              status {
                name
              }
              loanPolicy {
                name
                renewable
                renewalsPolicy {
                  numberAllowed
                  unlimited
                }
                loansPolicy {
                  period {
                    intervalId
                  }
                }
              }
            }
          }
          totalCharges {
            isoCurrencyCode
            amount
          }
          totalChargesCount
          totalLoans
          totalHolds
        }
      }",
      variables: { patronId: patron_uuid }
    })
    raise data['errors'].pluck('message').join("\n") if data.key?('errors')

    data.dig('data', 'patron')
  end

  def ping
    # Every GraphQL server supports the trivial query that asks for the "type name" of the top-level query
    # You can run a health check as a GET against an URL like this
    # See https://www.apollographql.com/docs/apollo-server/monitoring/health-checks/
    request('/graphql?query=%7B__typename%7D')
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
    DEFAULT_HEADERS.merge({ 'User-Agent': 'FolioGraphqlClient', 'okapi_username' => @username,
                            'okapi_password' => @password })
  end
end
