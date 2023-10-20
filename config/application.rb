# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mylibrary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

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
      # TODO: remove this first entry ILL after migrating off of Symphony.
      # SUL-ILB-REPLACE-ME is a placeholder for whatever the new FOLIO code will be.
      'ILL' => 'Interlibrary borrowing',
      'SUL-ILB-REPLACE-ME' => 'Interlibrary borrowing',
      'LANE-MED' => 'Medical Library (Lane)',
      'LATHROP' => 'Lathrop Library',
      'LAW' => 'Law Library (Crown)',
      'MATH-CS' => 'Math & Statistics Library',
      'MEDIA-MTXT' => 'Media & Microtext Center',
      'MUSIC' => 'Music Library',
      'RUMSEYMAP' => 'David Rumsey Map Center',
      'RWC' => 'Academy Hall (SRWC)',
      'SAL' => 'SAL1&2 (on-campus shelving)',
      'SAL3' => 'SAL3 (off-campus storage)',
      'SAL-NEWARK' => 'SAL Newark (off-campus storage)',
      'SCIENCE' => 'Science Library (Li and Ma)',
      'SPEC-COLL' => 'Special Collections',
      'SPEC-DESK' => 'Special Collections',
      # TODO: remove this first entry BORROW_DIRECT after migrating off of Symphony.
      # SUL-BORROW-DIRECT is the new FOLIO code.
      'BORROW_DIRECT' => 'BorrowDirect',
      'SUL-BORROW-DIRECT' => 'BorrowDirect',
      'TANNER' => 'Philosophy Library (Tanner)'
    }
  end
end
