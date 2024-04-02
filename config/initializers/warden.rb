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

Warden::Strategies.add(:library_id) do
  def valid?
    params['library_id'].present? && params['pin'].present?
  end

  def authenticate!
    response = FolioClient.new.login(params['library_id'], params['pin'])

    if response&.key?('patronKey') || response&.key?('id')
      u = { username: params['library_id'], patron_key: response['patronKey'] || response['id'] }
      success!(User.new(u))
    else
      fail!('Could not log in')
    end
  end
end
