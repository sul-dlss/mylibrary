# frozen_string_literal: true

begin
  require 'ruby-oci8'
rescue LoadError => e
  Rails.logger.error('ruby-oci8 gem not available; sponsor checkouts on behalf of the group will not display')
  Rails.logger.error(e)

  class OCIException < RuntimeError; end
end

# Oracle client to query Symphony database
class SymphonyDbClient
  CHECKOUTS_QUERY =
    'select catalog_key, call_sequence, copy_number, charge_number from charge ' \
    'where user_key = :user_key and usergroup_key >=0'
  REQUESTS_QUERY =
    'select key from hold where user_key = :user_key and usergroup_key >=0'
  FINES_QUERY =
    'select user_key, bill_number from bill where user_key = :user_key and usergroup_key >=0'

  def ping
    connection.ping
  rescue OCIException
    false
  end

  def group_circrecord_keys(patron_key)
    checkouts_cursor = cursor(CHECKOUTS_QUERY, patron_key)
    checkouts_cursor.exec

    checkouts_cursor.enum_for(:fetch).map { |row| row.join(':') }
  rescue OCIException => e
    Honeybadger.notify(e)
    []
  end

  def group_holdrecord_keys(patron_key)
    requests_cursor = cursor(REQUESTS_QUERY, patron_key)
    requests_cursor.exec

    requests_cursor.enum_for(:fetch).map { |row| row.join }
  rescue OCIException => e
    Honeybadger.notify(e)
    []
  end

  def group_billrecord_keys(patron_key)
    requests_cursor = cursor(FINES_QUERY, patron_key)
    requests_cursor.exec

    requests_cursor.enum_for(:fetch).map { |row| row.join(':') }
  rescue OCIException => e
    Honeybadger.notify(e)
    []
  end

  private

  def connection
    unless defined?(OCI8)
      Rails.logger.error('ruby-oci8 gem not available; sponsor checkouts on behalf of the group will not display')
      raise OCIException, 'ruby-oci8 gem not available'
    end

    OCI8.properties[:connect_timeout] = 5
    @connection ||= OCI8.new(connection_settings)
  end

  def config
    Settings.symphony_db
  end

  def connection_settings
    return '/' unless config

    "#{config.username}/#{config.password}@//#{config.host}/#{config.database}"
  end

  def cursor(query, patron_key)
    c = connection.parse(query)
    c.bind_param(':user_key', patron_key.to_i, Integer)
  end
end
