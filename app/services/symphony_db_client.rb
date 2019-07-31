# frozen_string_literal: true

# Oracle client to query Symphony database
class SymphonyDbClient
  attr_reader :patron_key

  def initialize(patron_key)
    @patron_key = patron_key.to_i
    @group_circrecord_keys = []
  end

  def connection
    @connection ||= OCI8.new(connection_settings)
  end

  def logoff
    @connection.logoff
  end

  def statement
    'select catalog_key, call_sequence, copy_number, charge_number from charge where user_key = :user_key and usergroup_key >=0'
  end

  def cursor
    @cursor ||= begin
      c = connection.parse(statement)
      c.bind_param(':user_key', patron_key, Integer)
    end
  end

  def group_circrecord_keys
    return @group_circrecord_keys if @group_circrecord_keys.any?

    cursor.exec
    cursor.fetch { |row| @group_circrecord_keys << row.join(':') }
    @group_circrecord_keys
  end

  private

  def config
    Settings.symphony_db
  end

  def connection_settings
    "#{config.username}/#{config.password}@//#{config.host}/#{config.database}"
  end
end
