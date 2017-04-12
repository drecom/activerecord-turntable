require "active_record"

module TurntableHelper
  def reload_turntable!(config_file_name = nil, env = :test)
    ActiveRecord::Base.include(ActiveRecord::Turntable)
    ActiveRecord::SchemaDumper.prepend(ActiveRecord::Turntable::ActiveRecordExt::SchemaDumper)
    ActiveRecord::Base.turntable_config_file = config_file_name
    ActiveRecord::Turntable::Config.load!(ActiveRecord::Base.turntable_config_file, :test)
    ActiveRecord::Base.logger = Logger.new("/dev/null")
    ActiveRecord::Base.establish_connection(env)
  end

  def migrate(version)
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, version)
  end
end
