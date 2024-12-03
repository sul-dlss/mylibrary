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

class BorrowDirectReshareCheck < OkComputer::Check
  def check
    if BorrowDirectReshareClient.new.ping
      mark_message 'Connected to BorrowDirect Reshare'
    else
      mark_failure
      mark_message 'Unable to connect to BorrowDirect Reshare'
    end
  end
end

OkComputer::Registry.register('okapi', OkapiCheck.new) if Settings.folio.okapi_url
OkComputer::Registry.register('graphql', GraphqlCheck.new) if Settings.folio.graphql_url
OkComputer::Registry.register('reshare', BorrowDirectReshareCheck.new) if Settings.borrow_direct_reshare.enabled

OkComputer.make_optional [('okapi' if Settings.folio.okapi_url),
                          ('graphql' if Settings.folio.graphql_url),
                          ('reshare' if Settings.borrow_direct_reshare.enabled)].compact
