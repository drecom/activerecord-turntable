$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'bundler/setup'

require 'activerecord-turntable'
require 'turntable_helper'

require 'coveralls'
Coveralls.wear!

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), 'migrations'))

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.mock_framework = :rr

  config.before(:each) do
  end
end
