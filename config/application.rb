require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mylibrary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Pacific Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.middleware.use Warden::Manager do |manager|
      manager.default_strategies :shibboleth
    end

    # Set SameSite protection to none so that we can receive POST requests
    # from Cybersource that include our authentication cookie
    config.action_dispatch.cookies_same_site_protection = :none

    config.library_contact = {
      'ARS' => 'soundarchive@stanford.edu',
      'ART' => 'artlibrary@stanford.edu',
      'BIOLOGY' => 'greencirc@stanford.edu',
      'BUSINESS' => 'gsb_librarycirc@stanford.edu',
      'CHEMCHMENG' => 'greencirc@stanford.edu',
      'CLASSICS' => 'classics@stanford.edu',
      'EARTH-SCI' => 'brannerlibrary@stanford.edu',
      'EAST-ASIA' => 'eastasialibrary@stanford.edu',
      'EDUCATION' => 'cubberley@stanford.edu',
      'ENG' => 'englibrary@stanford.edu',
      'GREEN' => 'greencirc@stanford.edu',
      'HOOVER' => 'hoover-library-archives@stanford.edu',
      'HOPKINS' => 'HMS-Library@lists.stanford.edu',
      'HV-ARCHIVE' => 'hoover-library-archives@stanford.edu',
      'LANE-MED' => 'laneaskus@stanford.edu',
      'LATHROP' => 'greencirc@stanford.edu',
      'LAW' => 'reference@law.stanford.edu',
      'MATH-CS' => 'greencirc@stanford.edu',
      'MEDIA-MTXT' => 'greencirc@stanford.edu',
      'MUSIC' => 'muslibcirc@stanford.edu',
      'RUMSEYMAP' => 'rumseymapcenter@stanford.edu',
      'SAL' => 'salcirculation@stanford.edu',
      'SAL3' => 'greencirc@stanford.edu',
      'SAL-NEWARK' => 'greencirc@stanford.edu',
      'SCIENCE' => 'sciencelibrary@stanford.edu',
      'SPEC-COLL' => 'specialcollections@stanford.edu',
      'SPEC-DESK' => 'specialcollections@stanford.edu',
      'TANNER' => 'tanner-library@stanford.edu'
    }
  end
end
