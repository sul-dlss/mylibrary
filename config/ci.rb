# Run using bin/ci

CI.run do
  step 'Setup', 'bin/setup --skip-server'

  step 'Style: Ruby', 'bin/rubocop'

  step 'Security: Importmap vulnerability audit', 'bin/importmap audit'
  step 'Tests: Rails', 'bin/rake'
  step 'Tests: Seeds', 'env RAILS_ENV=test bin/rails db:seed:replant'
end
