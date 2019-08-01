# frozen_string_literal: true

# Oracle client to query Symphony database
class SymphonyDbClient
  attr_reader :patron_key

  def initialize(patron_key)
    @patron_key = patron_key.to_i
  end

  def connection
    @connection ||= OCI8.new(connection_settings)
  end

  def logoff
    @connection.logoff
  end

  def checkouts_query
    'select catalog_key, call_sequence, copy_number, charge_number from charge' \
    ' where user_key = :user_key and usergroup_key >=0'
  end

  def cursor
    @cursor ||= begin
      c = connection.parse(checkouts_query)
      c.bind_param(':user_key', patron_key, Integer)
    end
  end

  def group_circrecord_keys
    @group_circrecord_keys ||= begin
      cursor.exec

      cursor.enum_for(:fetch).map { |row| row.join(':') }
    end
  end

  def requests_query
    'select key from hold where user_key = :user_key and usergroup_key >=0'
  end

  def requests_cursor
    @requests_cursor ||= begin
      c = connection.parse(requests_query)
      c.bind_param(':user_key', patron_key, Integer)
    end
  end

  def group_holdrecord_keys
    @group_holdrecord_keys ||= begin
      requests_cursor.exec

      requests_cursor.enum_for(:fetch).map { |row| row.join('') }
    end
  end

  private

  def config
    Settings.symphony_db
  end

  def connection_settings
    "#{config.username}/#{config.password}@//#{config.host}/#{config.database}"
  end
end
