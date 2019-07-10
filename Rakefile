# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  puts 'Unable to load RuboCop.'
end

begin
  require 'scss_lint/rake_task'
  SCSSLint::RakeTask.new do |t|
    t.config = '.scss-lint.yml'
  end
rescue LoadError
  puts 'Unable to load scss-lint'
end

Rails.application.load_tasks

task(:default).clear
task default: %i[rubocop scss_lint spec yarn_test]
