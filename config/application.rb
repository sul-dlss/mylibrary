# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mylibrary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.time_zone = 'Pacific Time (US & Canada)'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.middleware.use Warden::Manager do |manager|
      manager.default_strategies :shibboleth
    end

    config.library_map = {
      'ARS' => 'Archive of Recorded Sound',
      'ART' => 'Art & Architecture Library (Bowes)',
      'BIOLOGY' => 'Biology Library (Falconer)',
      'BUSINESS' => 'Business Library',
      'CHEMCHMENG' => 'Chemistry & ChemEng Library (Swain)',
      'CLASSICS' => 'Classics Library',
      'EARTH-SCI' => 'Earth Sciences Library (Branner)',
      'EAST-ASIA' => 'East Asia Library',
      'EDUCATION' => 'Education Library (Cubberley)',
      'ENG' => 'Engineering Library (Terman)',
      'GREEN' => 'Green Library',
      'HOOVER' => 'Hoover Library',
      'HOPKINS' => 'Marine Biology Library (Miller)',
      'HV-ARCHIVE' => 'Hoover Archives',
      'LANE-MED' => 'Medical Library (Lane)',
      'LATHROP' => 'Lathrop Library',
      'LAW' => 'Law Library (Crown)',
      'MATH-CS' => 'Math & Statistics Library',
      'MEDIA-MTXT' => 'Media & Microtext Center',
      'MUSIC' => 'Music Library',
      'RUMSEYMAP' => 'David Rumsey Map Center',
      'SAL' => 'SAL1&2 (on-campus shelving)',
      'SAL3' => 'SAL3 (off-campus storage)',
      'SAL-NEWARK' => 'SAL Newark (off-campus storage)',
      'SCIENCE' => 'Science Library (Li and Ma)',
      'SPEC-COLL' => 'Special Collections',
      'TANNER' => 'Philosophy Library (Tanner)'
    }
  end
end
