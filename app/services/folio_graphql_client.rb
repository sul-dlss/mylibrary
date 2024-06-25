# frozen_string_literal: true

require 'http'

class FolioGraphqlClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: Settings.folio.graphql_url, username: nil, password: nil, tenant: 'sul')
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

  # Overridden so that we don't display password
  def inspect
    "#<#{self.class.name}:#{object_id}  @base_url=\"#{base_url}\">"
  end

  def get(path, **)
    request(path, method: :get, **)
  end

  def post(path, **)
    request(path, method: :post, **)
  end

  def get_json(path, **)
    parse(get(path, **))
  end

  def post_json(path, **)
    parse(post(path, **))
  end

  def service_points
    data = post_json('/', json: {
      query: "query ServicePoints {
        servicePoints {
          discoveryDisplayName
          id
          code
          pickupLocation
          details {
            isDefaultForCampus
            isDefaultPickup
          }
        }
      }"
    })
    raise data['errors'].pluck('message').join("\n") if data.key?('errors')

    data.dig('data', 'servicePoints')
  end

  def loan_policies
    data = post_json('/', json: {
      query: "query LoanPolicies {
        loanPolicies {
          id
          name
          description
          renewable
          renewalsPolicy {
            numberAllowed
            alternateFixedDueDateSchedule {
              schedules {
                due
                from
                to
              }
            }
            period {
              duration
              intervalId
            }
            renewFromId
            unlimited
          }
          loanable
          loansPolicy {
            period {
              duration
              intervalId
            }
            fixedDueDateSchedule {
              schedules {
                due
                from
                to
              }
            }
          }
          requestManagement {
            holds {
              renewItemsWithRequest
            }
          }
        }
      }"
    })

    raise data['errors'].pluck('message').join("\n") if data.key?('errors')

    data.dig('data', 'loanPolicies')
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
            proxiesFor {
              userId
            }
            proxiesOf {
              proxyUserId
              proxyUser {
                barcode
                personal {
                  firstName
                  lastName
                }
              }
            }
            expirationDate
            externalSystemId
            patronGroup {
              desc
              group
              limits {
                conditionId
                id
                patronGroupId
                value
                condition {
                  blockBorrowing
                  blockRenewals
                  blockRequests
                  message
                  name
                  valueType
                }
              }
            }
            blocks {
              message
            }
            manualBlocks {
              desc
            }
            patronGroupId
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
                permanentLocation {
                  code
                }
                effectiveLocation {
                  code
                  details {
                    pageServicePoints {
                      code
                      id
                      discoveryDisplayName
                      pickupLocation
                    }
                  }
                }
                holdingsRecord {
                  effectiveLocation {
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
            details {
              holdShelfExpirationDate
              proxyUserId
              proxy {
                firstName
                lastName
                barcode
              }
            }
            pickupLocationId
            pickupLocation {
              code
            }
            queueTotalLength
            queuePosition
            cancellationReasonId
            canceledByUserId
            cancellationAdditionalInformation
            canceledDate
            patronComments
          }
          accounts {
            id
            userId
            remaining
            dateCreated
            amount
            loanId
            loan {
              proxyUserId
            }
            status {
              name
            }
            feeFine {
              feeFineType
            }
            actions {
              dateAction
              typeAction
            }
            metadata {
              createdDate
            }
            paymentStatus {
              name
            }
            item {
              id
              barcode
              effectiveShelvingOrder
              effectiveLocation {
                code
              }
              permanentLocation {
                code
              }
              instance {
                title
                hrid
                contributors {
                  name
                }
              }
              holdingsRecord {
                callNumber
                effectiveLocation {
                  code
                }
              }
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
                hrid
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
                permanentLoanTypeId
                temporaryLoanTypeId
                materialTypeId
                effectiveLocationId
                effectiveLocation {
                  code
                }
                permanentLocation {
                  code
                }
                holdingsRecord {
                  effectiveLocation {
                    code
                  }
                }
                queueTotalLength
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
              feesAndFines {
                amountRemainingToPay
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

    Honeybadger.notify(data['errors'].pluck('message').join("\n"), context: { patron_uuid: }) if data.key?('errors')

    data.dig('data', 'patron')
  end

  def ping
    # Every GraphQL server supports the trivial query that asks for the "type name" of the top-level query
    # You can run a health check as a GET against an URL like this
    # See https://www.apollographql.com/docs/apollo-server/monitoring/health-checks/
    request('/graphql?query=%7B__typename%7D').status == 200
  rescue HTTP::Error
    false
  end

  private

  def parse(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def request(path, headers: {}, method: :get, **)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'folio' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'User-Agent': 'FolioGraphqlClient', 'okapi_username' => @username,
                            'okapi_password' => @password })
  end
end
