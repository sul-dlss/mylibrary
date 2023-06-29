# frozen_string_literal: true

class CybersourceController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    params.merge!(Hash[*cybersource_params.map(&:to_a).flatten])
    apply_security_signature
    Rails.logger.info("RE-POSTING TO CYBERSOURCE: #{params}")
    Rails.logger.info("PAYMENT_URL:#{Settings.cybersource.payment_url}")
    repost(Settings.cybersource.payment_url, params: post_params)
  end

  private

  def cybersource_params
    [access_key, profile_id, signed_field_names, locale, transaction_type,
     currency, transaction_uuid, reference_number, merchant_defined_data1,
     merchant_defined_data2, unsigned_field_names]
  end

  def apply_security_signature
    params[:signed_date_time].to_s.empty? && params[:signed_date_time] = current_utc_xml_date_time
    params[:access_key].to_s.size.positive? && params[:signature] = Security.generate_signature(params)
  end

  def current_utc_xml_date_time
    current_utc_xml_date_time = Time.now.utc.strftime '%Y-%m-%dT%H:%M:%S%z'
    current_utc_xml_date_time = current_utc_xml_date_time[0, current_utc_xml_date_time.length - 5]
    current_utc_xml_date_time << 'Z'
    current_utc_xml_date_time
  end

  def locale
    { locale: 'en' }
  end

  def transaction_type
    { transaction_type: 'sale' }
  end

  def currency
    { currency: 'USD' }
  end

  def access_key
    { access_key: Settings.cybersource.access_key }
  end

  def profile_id
    { profile_id: Settings.cybersource.profile_id }
  end

  def transaction_uuid
    { transaction_uuid: SecureRandom.hex(16) }
  end

  def reference_number
    { reference_number: params[:userId] }
  end

  def merchant_defined_data1
    { merchant_defined_data1: params[:billseq] }
  end

  def merchant_defined_data2
    { merchant_defined_data2: params[:session_id] }
  end

  def unsigned_field_names
    { unsigned_field_names: 'merchant_defined_data1,merchant_defined_data2' }
  end

  def signed_field_names
    { signed_field_names: 'access_key,profile_id,transaction_uuid,' \
                          'signed_field_names,unsigned_field_names,' \
                          'signed_date_time,locale,transaction_type,' \
                          'reference_number,amount,currency' }
  end

  def post_params
    params.permit(%I[access_key profile_id transaction_uuid signed_field_names unsigned_field_names
                     signed_date_time locale transaction_type amount currency reference_number
                     merchant_defined_data1 merchant_defined_data2 signature]).to_h
  end
end
