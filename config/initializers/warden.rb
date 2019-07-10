# frozen_string_literal: true

Warden::Strategies.add(:shibboleth) do
  def valid?
    uid.present?
  end

  def authenticate!
    response = SymphonyClient.new.login_by_sunetid(uid)

    if response && response['key']
      u = { username: uid, patronKey: response['key'] }
      success!(u)
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
    response = SymphonyClient.new.login_by_sunetid(uid)

    if response && response['key']
      u = { username: uid, patronKey: response['key'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end

  private

  def uid
    ENV['uid']
  end
end

Warden::Strategies.add(:library_id) do
  def valid?
    params['library_id'].present? && params['pin'].present?
  end

  def authenticate!
    response = SymphonyClient.new.login(params['library_id'], params['pin'])

    if response['patronKey']
      u = { username: params['library_id'], name: response['name'], patronKey: response['patronKey'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end
end
