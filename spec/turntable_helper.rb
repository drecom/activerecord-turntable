require 'active_record'
ActiveRecord::Base.configurations = YAML.load_file(File.join(File.dirname(__FILE__), 'config/database.yml'))

def reload_turntable!(config_file_name = nil)
  ActiveRecord::Base.send(:include, ActiveRecord::Turntable)
  ActiveRecord::Base.turntable_config_file = config_file_name
  ActiveRecord::Turntable::Config.load!(ActiveRecord::Base.turntable_config_file, :test)
end

def establish_connection_to(env = "test")
  silence_warnings {
    Object.const_set('RAILS_ENV', env)
    Object.const_set('Rails', Object.new)
    stub(Rails).env { ActiveSupport::StringInquirer.new(RAILS_ENV) }
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  }
  ActiveRecord::Base.establish_connection(env)
  require File.expand_path(File.join(File.dirname(__FILE__),'./test_models'))
end

def truncate_shard
  ActiveRecord::Base.descendants.each do |klass|
    klass.delete_all
  end
end

def migrate(version)
  ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, version)
end
