# frozen_string_literal: true

OkComputer.mount_at = false
OkComputer.check_in_parallel = true

class OkapiCheck < OkComputer::Check
  def check
    if FolioClient.new.ping
      mark_message 'Connected to OKAPI'
    else
      mark_failure
      mark_message 'Unable to connect to OKAPI'
    end
  end
end

class GraphqlCheck < OkComputer::Check
  def check
    if FolioGraphqlClient.new.ping
      mark_message 'Connected to Folio GraphQL'
    else
      mark_failure
      mark_message 'Unable to connect to Folio GraphQL'
    end
  end
end

OkComputer::Registry.register('okapi', OkapiCheck.new) if Settings.folio.url
OkComputer::Registry.register('graphql', GraphqlCheck.new) if Settings.folio_graphql.url
OkComputer.make_optional %w[okapi graphql]
