# frozen_string_literal: true

desc 'Run JavaScript tests'
task :yarn_test do
  `yarn test`
end
