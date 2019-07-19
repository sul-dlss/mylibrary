# frozen_string_literal: true

# HTTP client wrapper for making requests to Symws
class SymphonyLegacyClient
  def payments(session_token, patron)
    response = request('/rest/patron/lookupPatronInfo', params: {
      clientID: 'SymWSTestClient',
      sessionToken: session_token,
      userID: patron.barcode,
      includeFeeInfo: 'PAID_FEES_AND_PAYMENTS',
      allowedDisplayGroupFees: true
    })

    response.body
  end

  private

  def request(path, method: :get, **other)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'symphony' })
      .request(method, base_url + path, **other)
  end

  def base_url
    Settings.symws.url
  end
end
