# frozen_string_literal: true

require 'sinatra/base'

class FakeGraphql < Sinatra::Base
  post '/' do
    content_type :json
    status 200

    {}.to_json
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.binread("#{File.dirname(__FILE__)}/fixtures/#{file_name}")
  end
end
