require 'sinatra'
require 'securerandom'
require './security'

include ERB::Util

#set :erubis, :escape_html => true

get '/' do
  erb :signeddatafields
end

post '/unsigneddatafields' do

  if params['signed_date_time'].to_s.size == 0
    current_utc_xml_date_time = Time.now.utc.strftime "%Y-%m-%dT%H:%M:%S%z"
    current_utc_xml_date_time = current_utc_xml_date_time[0, current_utc_xml_date_time.length-5]
    current_utc_xml_date_time << 'Z'
    params.store 'signed_date_time', current_utc_xml_date_time
  end

  if params['access_key'].to_s.size > 0
    params.store 'signature', Security.generate_signature(params)

  end

  erb :unsigneddatafields
end

post '/receipt' do
  @signature_valid = Security.valid? params
  erb :receipt
end

post '/backoffice' do
  puts "Backoffice POST notification received: #{params}"
end
