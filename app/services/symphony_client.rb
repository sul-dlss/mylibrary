# frozen_string_literal: true

# HTTP client wrapper for making requests to Symws
class SymphonyClient
  class IlsError < StandardError; end

  DEFAULT_HEADERS = {
    accept: 'application/json',
    content_type: 'application/json'
  }.freeze

  # ping the symphony endpoint to make sure we can establish a connection
  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  def login(library_id, pin)
    response = authenticated_request('/user/patron/authenticate', method: :post, json: {
      barcode: library_id,
      password: pin
    })

    JSON.parse(response.body)
  end

  def login_by_sunetid(sunetid)
    response = authenticated_request('/user/patron/search', params: {
      q: "webAuthID:#{sunetid}",
      includeFields: '*'
    })

    JSON.parse(response.body)['result'].first
  end

  # get a session token by authenticating to symws
  def session_token
    @session_token ||= begin
      response = request('/user/staff/login', json: Settings.symws.login_params, method: :post)

      JSON.parse(response.body)['sessionToken']
    rescue JSON::ParserError
      Honeybadger.notify('Unable to connect to Symphony Web Services.')
      nil
    end
  end

  ITEM_RESOURCES = 'bib{title,author,callList{*}},item{*,bib{title,author},call{sortCallNumber,dispCallNumber}}'

  def patron_linked_resources_fields(item_details = {})
    [
      "holdRecordList{*,#{ITEM_RESOURCES if item_details[:holdRecordList]}}",
      'circRecordList{*,circulationRule{loanPeriod{periodType{key}},renewFromPeriod},' \
      "#{item_details[:circRecordList] ? ITEM_RESOURCES : 'item{itemCategory5}'}}",
      "blockList{*,#{ITEM_RESOURCES if item_details[:blockList]}}",
      'groupSettings{*,responsibility}'
    ]
  end

  # rubocop:disable Metrics/MethodLength
  def patron_info(patron_key, item_details: {})
    response = authenticated_request("/user/patron/key/#{patron_key}", params: {
      includeFields: [
        '*',
        'address1',
        'profile{chargeLimit}',
        'customInformation{*}',
        "groupSettings{*,group{memberList{*,#{patron_linked_resources_fields(item_details).join(',')}}}}",
        *patron_linked_resources_fields(item_details)
      ].join(',')
    })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def circ_record_info(circ_record_key)
    response = authenticated_request("/circulation/circRecord/key/#{circ_record_key}", params: {
      includeFields: [
        '*',
        ITEM_RESOURCES
      ].join(',')
    })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def catalog_info(key)
    response = authenticated_request("/catalog/item/barcode/#{ERB::Util.url_encode(key)}", params: {
      includeFields: [
        '*',
        'bib{holdRecordList{*,item{call,bib{title}}}}',
        'call{*,itemList{*}}',
        'currentLocation'
      ].join(',')
    })

    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end
  # rubocop:enable Metrics/MethodLength

  def reset_pin(library_id, reset_path)
    response = request('/user/patron/resetMyPin', method: :post, json: {
      login: library_id,
      resetPinUrl: reset_path
    })
    raise IlsError, response.body unless response.status == 200

    JSON.parse(response.body)
  end

  def change_pin(token, pin)
    response = request(
      '/user/patron/changeMyPin',
      method: :post,
      json: { resetPinToken: token, newPin: pin },
      headers: { 'x-sirs-clientID': Settings.symws.public_clientID }
    )
    raise IlsError, response.body unless response.status == 200
  end

  def renew_item(resource, item_key, _patron_key = nil)
    response = renew_item_request(resource, item_key)
    error_prompt = response_prompt(response)

    if error_prompt == 'CIRC_HOLDS_OVRCD'
      renew_item_request(resource,
                         item_key,
                         headers: { 'SD-Prompt-Return': "#{error_prompt}/#{Settings.symphony.override}" })
    else
      response
    end
  end

  def renew_items(checkouts)
    checkouts.each_with_object(success: [], error: []) do |checkout, status|
      response = renew_item(checkout.resource, checkout.item_key)

      case response.status
      when 200
        status[:success] << checkout
      else
        status[:error] << checkout
      end
    end
  end

  def cancel_hold(resource, item_key, _patron_key = nil)
    authenticated_request('/circulation/holdRecord/cancelHold', method: :post, json: {
      holdRecord: {
        resource: resource,
        key: item_key
      }
    })
  end

  def change_pickup_library(resource, item_key, service_point)
    authenticated_request('/circulation/holdRecord/changePickupLibrary', method: :post, json: {
      holdRecord: {
        resource: resource,
        key: item_key
      },
      pickupLibrary: {
        resource: '/policy/library',
        key: service_point
      }
    })
  end

  def not_needed_after(resource, item_key, not_needed_after)
    authenticated_request("/circulation/holdRecord/key/#{item_key}", method: :put, json: {
      resource: resource,
      key: item_key,
      fields: {
        fillByDate: not_needed_after
      }
    })
  end

  # Once Cybersource indicates payment was successful, call a script on the
  # Symphony server that will update the fines as paid
  def pay_fines(user:, amount:, session_id:)
    # Mimic the data that Cybersource used to POST back to Symphony directly
    params = {
      req_merchant_defined_data1: user,
      req_amount: amount,
      req_reference_number: session_id,
      req_bill_to_email: '',
      decision: 'ACCEPT'
    }

    response = HTTP.use(instrumentation: instrumentation)
                   .request(:post, "#{cgi_bin_url}/transactionPost.pl", form: params)

    raise IlsError, response.body unless response.status == 200
  end

  private

  def renew_item_request(resource, item_key, headers: {})
    authenticated_request('/circulation/circRecord/renew', headers: headers, method: :post, json: {
      item: {
        resource: resource,
        key: item_key
      }
    })
  end

  def response_prompt(response)
    return if response.status.ok?

    JSON.parse(response.body).dig('dataMap', 'promptType')
  rescue JSON::ParserError
    nil
  end

  def authenticated_request(path, headers: {}, **other)
    request(path, headers: headers.merge('x-sirs-sessionToken': session_token), **other)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .use(instrumentation: instrumentation)
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def base_url
    Settings.symws.url
  end

  def cgi_bin_url
    "https://#{Settings.symphony.host}/cgi-bin"
  end

  def default_headers
    DEFAULT_HEADERS.merge(Settings.symws.headers || {})
  end

  def instrumentation
    { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'symphony' }
  end
end
