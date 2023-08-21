# frozen_string_literal: true

OkComputer.mount_at = false

if Settings.ils.client == 'SymphonyClient' && !Settings.folio_migration
  # OKComputer check that checks if we have a connection to symws
  class SymphonyClientCheck < OkComputer::Check
    def check
      ping = SymphonyClient.new.ping

      mark_failure unless ping
    end
  end

  OkComputer::Registry.register 'symphony_web_services', SymphonyClientCheck.new
end
