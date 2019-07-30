# frozen_string_literal: true

# :nodoc:
class User
  include ActiveModel::Model
  attr_accessor :username, :patron_key, :privgroups, :shibboleth

  # FIXME: This is temporary code and can be removed after everyone who has logged into -dev
  # has logged out and logged in.
  def initialize(attributes)
    super(attributes.with_indifferent_access.slice(:username, :patron_key, :privgroups, :shibboleth))
  end

  alias shibboleth? shibboleth

  def has_borrow_direct_access?
    ((privgroups || []) & Settings.auth.borrow_direct_privgroups).any?
  end
end
