# frozen_string_literal: true

# HTTP client wrapper for making requests to Symws
class SymphonyLegacyClient
  def payments(session_token, patron)
    response = request('/rest/patron/lookupPatronInfo', params: {
      clientID: Settings.symws.headers['x-sirs-clientID'],
      sessionToken: session_token,
      userID: patron.barcode,
      includeFeeInfo: 'PAID_FEES_AND_PAYMENTS',
      allowedDisplayGroupFees: true
    })

    (Hash.from_xml(response.body.to_s) || {}).dig('LookupPatronInfoResponse', 'feeInfo') || []
  end

  private

  def request(path, method: :get, **)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'symphony' })
      .request(method, base_url + path, **)
  end

  def base_url
    Settings.symws.url
  end
end
