# frozen_string_literal: true

# :nodoc:
class IlsLogSubscriber < ActiveSupport::LogSubscriber
  def start_request(event)
    return unless logger.debug?

    request = event.payload[:request]

    debug "  [HTTP] > #{request.verb.to_s.upcase} #{request.uri}"
  end

  def request(event)
    return unless logger.debug?

    response = event.payload[:response]

    debug "  [HTTP] < #{response.status} #{response.mime_type} (#{event.duration.round(3)}ms)"
  end
end

IlsLogSubscriber.attach_to :symphony
IlsLogSubscriber.attach_to :folio
