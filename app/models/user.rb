# frozen_string_literal: true

# :nodoc:
class User
  include ActiveModel::Model
  attr_accessor :username, :patron_key, :shibboleth

  alias shibboleth? shibboleth
end
