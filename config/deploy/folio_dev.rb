# frozen_string_literal: true

set :rails_env, 'production'

server 'mylibrary-dev.stanford.edu', user: 'mylibrary', roles: %w[web db app]

set :bundle_without, %w[deployment test].join(' ')

Capistrano::OneTimeKey.generate_one_time_key!
