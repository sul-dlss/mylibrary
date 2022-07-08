# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

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
      'BORROW_DIRECT' => 'BorrowDirect',
      'BUSINESS' => 'Business Library',
      'CDL' => 'Digital lending',
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
      'ILL' => 'Interlibrary borrowing',
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
      'TANNER' => 'Philosophy Library (Tanner)'
    }

    config.pickup_libraries = [
      'BUSINESS',
      'EAST-ASIA',
      'GREEN',
      'HOPKINS',
      'LAW'
    ]

    config.library_specific_pickup_libraries = {
      'RUMSEYMAP' => ['SPEC-COLL'],
      'SPEC-COLL' => ['SPEC-COLL']
    }

    config.location_specific_pickup_libraries = {
      'PAGE-EA' => ['EAST-ASIA'],
      'HY-PAGE-EA' => ['EAST-ASIA'],
      'L-PAGE-EA'  => ['EAST-ASIA'],
      'ND-PAGE-EA' => ['EAST-ASIA'],
      'ARTLCKL' => ['SPEC-COLL'],
      'ARTLCKL-R' => ['SPEC-COLL'],
      'ARTLCKM' => ['SPEC-COLL'],
      'ARTLCKM-R' => ['SPEC-COLL'],
      'ARTLCKO' => ['SPEC-COLL'],
      'ARTLCKO-R' => ['SPEC-COLL'],
      'ARTLCKS' => ['SPEC-COLL'],
      'ARTLCKS-R' => ['SPEC-COLL'],
      'PAGE-GR' => ['GREEN'],
      'PAGE-SP' => ['SPEC-COLL']
    }
  end
end
