$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require "bundler/setup"

require "rails"
require "action_view"
require "action_dispatch"
require "action_controller"

require "activerecord-turntable"
require "active_record/turntable/active_record_ext/fixtures"

require "rspec/its"
require "rspec/collection_matchers"
require "rspec/parameterized"
require "rspec/rails"
require "webmock/rspec"
require "timecop"
require "pry-byebug"
require "factory_girl"
require "faker"

require "coveralls"
Coveralls.wear!

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "migrations"))

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
ActiveRecord::Base.configurations = YAML.load_file(File.join(File.dirname(__FILE__), "config/database.yml"))
ActiveRecord::Base.establish_connection(:test)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  include TurntableHelper

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = true

  config.before(:suite) do
    reload_turntable!(File.join(File.dirname(__FILE__), "config/turntable.yml"), :test)
  end

  config.include FactoryGirl::Syntax::Methods
  config.before(:suite) do
    FactoryGirl.find_definitions
  end

  config.before(:each) do
    Dir[File.join(File.dirname(File.dirname(__FILE__)), "spec/models/*.rb")].each { |f| require f }
  end
end
