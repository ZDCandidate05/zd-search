
# Lets you run the tests with `bundle exec rake spec`
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = ['--format', 'documentation', '--require', 'spec_helper']
end
