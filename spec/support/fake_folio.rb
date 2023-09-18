# frozen_string_literal: true

require 'sinatra/base'

class FakeFolio < Sinatra::Base
  post '/authn/login' do
    content_type :json
    status 201
    headers['x-okapi-token'] = 'session_token'

    {}.to_json
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.binread("#{File.dirname(__FILE__)}/fixtures/#{file_name}")
  end
end
