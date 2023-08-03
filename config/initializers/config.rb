# frozen_string_literal: true

Config.setup do |config|
  # Name of the constant exposing loaded settings
  config.const_name = 'Settings'
  # Load values from the environment; SETTINGS__FOO__BAR_BAZ => Settings.foo.bar_baz
  config.use_env = true
  config.env_prefix = 'SETTINGS'
  config.env_separator = '__'
  config.env_converter = :downcase
end
