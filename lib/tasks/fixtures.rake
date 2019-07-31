# frozen_string_literal: true

namespace :fixtures do
  desc 'create a patron fixture by pulling the patron information from Symphony'
  task :create, [:patron_key] => :environment do |_t, args|
    patron_key = args[:patron_key]

    File.open(Rails.root + "./spec/support/fixtures/patron/#{patron_key}.json", 'w') do |f|
      f.write JSON.pretty_generate(SymphonyClient.new.patron_info(patron_key, item_details: {
        blockList: true,
        circRecordList: true,
        holdRecordList: true
      }))
    end
  end
end
