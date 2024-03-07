# frozen_string_literal: true

Warden::Manager.serialize_into_session do |user|
  user&.as_json
end

Warden::Manager.serialize_from_session do |json|
  User.new(json) if json
end

Warden::Strategies.add(:shibboleth) do
  def valid?
    uid.present?
  end

  def authenticate!
    response = FolioClient.new.login_by_sunetid(uid)

    if response&.key?('key') || response&.key?('id')
      u = { username: uid, patron_key: response['key'] || response['id'], shibboleth: true }
      success!(User.new(u))
    else
      fail!('Could not log in')
    end
  end

  private

  def uid
    env['uid']
  end
end

Warden::Strategies.add(:development_shibboleth_stub) do
  def valid?
    Rails.env.development? && uid.present?
  end

  def authenticate!
    response = FolioClient.new.login_by_sunetid(uid)

    if response&.key?('key') || response&.key?('id')
      u = { username: uid, patron_key: response['key'] || response['id'] }
      success!(User.new(u))
    else
      fail!('Could not log in')
    end
  end

  private

  def uid
    ENV.fetch('uid', nil)
  end
end

Warden::Strategies.add(:university_id) do
  # Reviewing numbers input in the FOLIO "External System ID", it appears that
  # we have user records with 8, 9 and 10 digits.
  #
  # * Core community users (who presumably would be accessing our applications
  #   using auth and NOT inputting an ID) have 8 digits in the FOLIO External
  #   System ID field
  # * Courtesy card holders (the primary user group that we're trying to help
  #   gain access in sul-requests & My Account) have either 9 or 10 digits in
  #   FOLIO External System ID field.
  #
  # Until we're ready to completely roll out university ID login, we're also
  # supporting the old library id (barcode) input.
  def valid?
    params['university_id'].present? &&
      params['pin'].present?
  end

  def authenticate!
    response = FolioClient.new.login(params['university_id'], params['pin'])

    if response&.key?('patronKey') || response&.key?('id')
      u = { username: params['university_id'], patron_key: response['patronKey'] || response['id'] }
      success!(User.new(u))
    else
      fail!('Could not log in')
    end
  end
end
