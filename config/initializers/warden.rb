# frozen_string_literal: true

Warden::Strategies.add(:shibboleth) do
  def valid?
    remote_user.present?
  end

  def authenticate!
    response = SymphonyClient.new.login_by_sunetid(remote_user)

    if response && response['key']
      u = { username: remote_user, patronKey: response['key'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end

  private

  def remote_user
    env['REMOTE_USER']
  end
end

Warden::Strategies.add(:development_shibboleth_stub) do
  def valid?
    Rails.env.development? && remote_user.present?
  end

  def authenticate!
    response = SymphonyClient.new.login_by_sunetid(remote_user)

    if response && response['key']
      u = { username: remote_user, patronKey: response['key'] }
      success!(u)
    else
      fail!('Could not log in')
    end
  end

  private

  def remote_user
    ENV['REMOTE_USER']
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
