module ActiveRecord::Turntable
  module ActiveRecordExt
    extend ActiveSupport::Concern

    autoload :AbstractAdapter, 'active_record/turntable/active_record_ext/abstract_adapter'
    autoload :CleverLoad, 'active_record/turntable/active_record_ext/clever_load'
    autoload :DatabaseTasks, 'active_record/turntable/active_record_ext/database_tasks'
    autoload :LogSubscriber, 'active_record/turntable/active_record_ext/log_subscriber'
    autoload :Persistence, 'active_record/turntable/active_record_ext/persistence'
    autoload :SchemaDumper, 'active_record/turntable/active_record_ext/schema_dumper'
    autoload :Sequencer, 'active_record/turntable/active_record_ext/sequencer'
    autoload :Transactions, 'active_record/turntable/active_record_ext/transactions'

    included do
      include Transactions
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Sequencer)
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, AbstractAdapter)
      ActiveRecord::Tasks::DatabaseTasks.send(:include, DatabaseTasks)
      ActiveRecord::LogSubscriber.send(:include, LogSubscriber)
      ActiveRecord::Persistence.send(:include, Persistence)
      ActiveRecord::Relation.send(:include, CleverLoad)
      ActiveRecord::Migration.send(:include, ActiveRecord::Turntable::Migration)
      require 'active_record/turntable/active_record_ext/fixtures'
    end
  end
end
