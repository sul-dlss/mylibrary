# frozen_string_literal: true

# Controller for the requests page
class RequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    @response = symphony_client.requests(current_user.patron_key)
    @requests = @response['fields']['holdRecordList'].map { |request| Request.new(request) }
  end
end
