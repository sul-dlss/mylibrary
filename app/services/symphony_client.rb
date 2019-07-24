# frozen_string_literal: true

# HTTP client wrapper for making requests to Symws
class SymphonyClient
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
    end
  end

  ITEM_RESOURCES = 'item{*,bib{title,author},call{sortCallNumber,dispCallNumber}}'

  PATRON_LINKED_RESOURCES = [
    "holdRecordList{*,#{ITEM_RESOURCES}}",
    "circRecordList{*,circulationRule{loanPeriod{periodType{key}},renewFromPeriod},#{ITEM_RESOURCES}}",
    "blockList{*,#{ITEM_RESOURCES}}",
    'groupSettings{*,responsibility}'
  ].freeze

  def patron_info(patron_key)
    response = authenticated_request("/user/patron/key/#{patron_key}", params: {
      includeFields: [
        '*',
        'address1',
        'profile{chargeLimit}',
        "groupSettings{*,group{memberList{*,#{PATRON_LINKED_RESOURCES.join(',')}}}}",
        *PATRON_LINKED_RESOURCES
      ].join(',')
    })

    JSON.parse(response.body)
  end

  def reset_pin(library_id, reset_path)
    response = request('/user/patron/resetMyPin', method: :post, json: {
      login: library_id,
      resetPinUrl: reset_path
    })

    JSON.parse(response.body)
  end

  def change_pin(token, pin)
    response = request('/user/patron/changeMyPin', method: :post, json: {
      resetPinToken: token,
      newPin: pin
    })

    response
  end

  def renew_item(resource, item_key)
    response = authenticated_request('/circulation/circRecord/renew', method: :post, json: {
      item: {
        resource: resource,
        key: item_key
      }
    })

    response
  end

  def renew_items(checkouts)
    checkouts.each_with_object(success: [], error: []) do |checkout, flash|
      response = renew_item(checkout.resource, checkout.item_key)

      case response.status
      when 200
        flash[:success] << I18n.t('mylibrary.renew_item.success_html', title: checkout.title)
      else
        flash[:error] << I18n.t('mylibrary.renew_item.error_html', title: checkout.title)
      end
    end
  end

  def cancel_hold(resource, item_key)
    Rails.logger.info "#{[resource, item_key]} is not yet being cancelled, waiting for user setup"
    response = authenticated_request('/circulation/holdRecord/cancelHold', method: :post, json: {
      # TODO: Uncomment this when we can get a user to cancel requests for
      # item: {
      #   resource: resource,
      #   key: item_key
      # }
    })

    response
  end

  # rubocop:disable Metrics/MethodLength
  def change_pickup_library(resource, item_key, pickup_library)
    response = authenticated_request('/circulation/holdRecord/changePickupLibrary', method: :post, json: {
      holdRecord: {
        resource: resource,
        key: item_key
      },
      pickupLibrary: {
        resource: '/policy/library',
        key: pickup_library
      }
    })

    response
  end
  # rubocop:enable Metrics/MethodLength

  def not_needed_after(resource, item_key, not_needed_after)
    response = authenticated_request("/circulation/holdRecord/key/#{item_key}", method: :put, json: {
      resource: resource,
      key: item_key,
      fields: {
        fillByDate: not_needed_after
      }
    })

    response
  end

  private

  def authenticated_request(path, headers: {}, **other)
    request(path, headers: headers.merge('x-sirs-sessionToken': session_token), **other)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'symphony' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def base_url
    Settings.symws.url
  end

  def default_headers
    DEFAULT_HEADERS.merge(Settings.symws.headers || {})
  end
end
