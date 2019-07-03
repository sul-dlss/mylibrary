set :rails_env, 'production'

server 'mylibrary-uat.stanford.edu', user: 'mylibrary', roles: %w(web db app)

set :bundle_without, %w{deployment test}.join(' ')

Capistrano::OneTimeKey.generate_one_time_key!
