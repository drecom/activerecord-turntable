$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'bundler/setup'
require 'rspec/its'
require 'rspec/collection_matchers'
require 'webmock/rspec'
require 'pry'
require 'pry-byebug'

require 'activerecord-turntable'

require 'coveralls'
Coveralls.wear!

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), 'migrations'))

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
ActiveRecord::Base.configurations = YAML.load_file(File.join(File.dirname(__FILE__), 'config/database.yml'))
ActiveRecord::Base.establish_connection(:test)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  include TurntableHelper

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    Dir[File.join(File.dirname(File.dirname(__FILE__)), 'spec/models/*.rb')].each { |f| require f }
  end
end
