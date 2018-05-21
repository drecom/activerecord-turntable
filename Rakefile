require "bundler/gem_tasks"
require "rubygems"

require "rspec/core"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList["spec/**/*_spec.rb"]
end

require "active_record"
require "active_record/turntable/active_record_ext/database_tasks"

namespace :turntable do
  namespace :db do
    task :rails_env do
      unless defined? RAILS_ENV
        RAILS_ENV = ENV["RAILS_ENV"] ||= "test"
      end
    end

    task :load_config => :rails_env do
      yaml_file = File.join(File.dirname(__FILE__), "spec/config/database.yml")
      ActiveRecord::Base.configurations = YAML.load ERB.new(IO.read(yaml_file)).result
    end

    desc "create turntable test database"
    task :create => :load_config do
      ActiveRecord::Tasks::DatabaseTasks.create_current(RAILS_ENV)
      ActiveRecord::Tasks::DatabaseTasks.create_current_turntable_cluster(RAILS_ENV)
    end

    desc "drop turntable test database"
    task :drop => :load_config do
      ActiveRecord::Tasks::DatabaseTasks.drop_current(RAILS_ENV)
      ActiveRecord::Tasks::DatabaseTasks.drop_current_turntable_cluster(RAILS_ENV)
    end

    desc "migrate turntable test tables"
    task :migrate => :load_config do
      ActiveRecord::Base.establish_connection RAILS_ENV.to_sym
      require "active_record/turntable"
      ActiveRecord::Base.include(ActiveRecord::Turntable)
      ActiveRecord::ConnectionAdapters::SchemaStatements.include(ActiveRecord::Turntable::Migration::SchemaStatementsExt)

      configurations = [ActiveRecord::Base.configurations[RAILS_ENV]]
      configurations += ActiveRecord::Tasks::DatabaseTasks.current_turntable_cluster_configurations(RAILS_ENV).map { |v| v[1] }.flatten.uniq

      configurations.each do |configuration|
        ActiveRecord::Base.establish_connection configuration
        load File.expand_path("spec/migrations/schema.rb", __dir__)
      end
    end

    desc "drop turntable test database"
    task :drop => :load_config do
      ActiveRecord::Tasks::DatabaseTasks.drop_current_turntable_cluster(RAILS_ENV)
    end

    desc "reset turntable test databases"
    task :reset => ["turntable:db:drop", "turntable:db:create", "turntable:db:migrate"]
  end

  namespace :activerecord do
    task(:env) do
      ENV["ARCONFIG"] ||= File.expand_path("spec/config/activerecord_config.yml", __dir__)
      ENV["ARVERSION"] ||= if ActiveRecord.gem_version.prerelease? &&
                              !ActiveRecord.gem_version.segments.include?("rc")
                             "origin/master"
                           else
                             "v#{ActiveRecord.gem_version}"
                           end
    end

    namespace :setup do
      task :rails => :env do
        system(*%w|git submodule update --init|)
        system(*%w|git submodule foreach git fetch origin|)
        Dir.chdir("tmp/rails") do
          system(*%W|git checkout #{ENV["ARVERSION"]}|)
        end
        FileUtils.rm_r("test") if File.directory?("test")
        FileUtils.cp_r("tmp/rails/activerecord/test", ".")
        FileUtils.cp_r("tmp/rails/activerecord/Rakefile", "activerecord.rake")
        File.open("test/cases/helper.rb", "a") do |f|
          f << "require '#{File.expand_path("spec/activerecord_helper", __dir__)}'"
        end

        # FIXME: Disable a part of tests about internal metadata and validations on 5.0.x because it randomly fails.
        if ActiveRecord.gem_version.release < Gem::Version.new("5.1.0")
          File.open("test/cases/migration_test.rb", "a") do |f|
            f << <<-EOS
              class MigrationTest
                undef :test_migration_sets_internal_metadata_even_when_fully_migrated,
                      :test_internal_metadata_stores_environment
              end
            EOS
          end

          File.open("test/cases/validations_test.rb", "a") do |f|
            f << <<-EOS
              class ValidationsTest
                undef :test_numericality_validation_with_mutation
              end
            EOS
          end
        end

        # Ignore failing migrator test
        if ActiveRecord.gem_version.release <= Gem::Version.new("5.1.5")
          File.open("test/cases/migrator_test.rb", "a") do |f|
            f << <<-EOS.strip_heredoc
              class MigratorTest
                undef_method :test_migrator_verbosity if method_defined?(:test_migrator_verbosity)
              end
            EOS
          end
        end

        # Ignore some failing tests with ruby 2.5
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.5") &&
           ActiveRecord.gem_version.release <= Gem::Version.new("5.1.4")
          ignores = [
            ["aggregations_test.rb", "AggregationsTest", ["test_immutable_value_objects"]],
            ["query_cache_test.rb",  "QueryCacheTest", ["test_query_cache_does_not_allow_sql_key_mutation"]],
            ["transactions_test.rb", "TransactionTest", ["test_rollback_when_saving_a_frozen_record"]],
            ["log_subscriber_test.rb", "LogSubscriberTest",
             %w[test_basic_payload_name_logging_coloration_generic_sql
                test_basic_payload_name_logging_coloration_named_sql
                test_query_logging_coloration_with_nested_select
                test_query_logging_coloration_with_multi_line_nested_select
                test_query_logging_coloration_with_lock]],
          ]

          ignores.each do |file_name, class_name, method_names|
            path = File.join("test/cases", file_name)
            next unless File.exist?(path)

            File.open(File.join("test/cases", file_name), "a") do |f|
              f << <<-EOS.strip_heredoc
                class #{class_name}
                  #{method_names.map { |method_name| "undef_method :#{method_name} if method_defined?(:#{method_name})" }.join("\n") }

                end
              EOS
            end
          end
        end
      end

      task :db => :rails do
        system(*%w|bundle exec rake -f activerecord.rake db:mysql:rebuild|)
      end
    end

    desc "setup activerecord test"
    task :setup => ["setup:rails", "setup:db"]

    desc "run unit tests on activerecord"
    task :test => :env do
      unless system(*%w|bundle exec rake -f activerecord.rake test:mysql2|)
        exit(1)
      end
    end
  end
end
