require 'sinatra'
require './store_front'

$stdout.sync = true

run Sinatra::Application
