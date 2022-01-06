# frozen_string_literal: true

require 'sinatra/base'

class FakeSymphony < Sinatra::Base
  post '/symws/user/staff/login' do
    content_type :json
    status 200

    { sessionToken: 'the-fake-session-token' }.to_json
  end

  post '/symws/user/patron/resetMyPin' do
    content_type :json
    status 200
    {}.to_json
  end

  post '/symws/user/patron/changeMyPin' do
    content_type :json
    status 200
    {}.to_json
  end

  post '/symws/circulation/circRecord/renew' do
    content_type :json
    status 200
    {}.to_json
  end

  post '/symws/circulation/holdRecord/cancelHold' do
    content_type :json
    status 200
    {}.to_json
  end

  post '/symws/circulation/holdRecord/changePickupLibrary' do
    content_type :json
    status 200
    {}.to_json
  end

  put '/symws/circulation/holdRecord/key/:key' do
    content_type :json
    status 200
    {}.to_json
  end

  get '/symws/user/patron/key/:key' do
    json_response 200, "patron/#{params[:key]}.json"
  end

  get '/symws/circulation/circRecord/key/:key' do
    json_response 200, "circ_record/#{params[:key]}.json"
  end

  get '/symws/rest/patron/lookupPatronInfo' do
    content_type :'text/html'
    status 200
    begin
      File.read(File.dirname(__FILE__) + '/fixtures/patron/payment_history/' + "#{params['userID']}.xml")
    rescue Errno::ENOENT
      '<xml />'
    end
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.binread(File.dirname(__FILE__) + '/fixtures/' + file_name)
  end
end
