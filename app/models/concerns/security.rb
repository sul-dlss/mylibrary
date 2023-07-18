# frozen_string_literal: true

class Security
  require 'hmac-sha2'
  require 'base64'

  @secret_key = Settings.cybersource.secret_key.to_s

  def self.generate_signature(params)
    sign(build_data_to_sign(params),@secret_key)
  end

  def self.valid?(params)
    signature = generate_signature params
    signature.strip.eql? params['signature'].strip
  end

  def self.sign(data, secret_key)
    mac = HMAC::SHA256.new secret_key
    mac.update data
    Base64.encode64(mac.digest).delete("\n")
  end

  def self.build_data_to_sign(params)
    signed_field_names = params['signed_field_names'].split ','
    data_to_sign = []
    signed_field_names.each { |signed_field_name|
      data_to_sign << "#{signed_field_name}=#{params[signed_field_name]}"
    }
    comma_separate data_to_sign
  end

  def self.comma_separate(data_to_sign)
    csv = +''
    data_to_sign.length.times do |i|
      csv << data_to_sign[i]
      csv << ',' if i != data_to_sign.length - 1
    end
    csv
  end
end
