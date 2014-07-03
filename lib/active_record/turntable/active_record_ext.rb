module ActiveRecord::Turntable
  module ActiveRecordExt
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :AbstractAdapter
      autoload :CleverLoad
      autoload :ConnectionHandlerExtension
      autoload :LogSubscriber
      autoload :Persistence
      autoload :SchemaDumper
      autoload :Sequencer
      autoload :Relation
      autoload :Transactions
      autoload :AssociationPreloader
      autoload :Association
      autoload :LockingOptimistic
    end

    included do
      include Transactions
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Sequencer)
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, AbstractAdapter)
      ActiveRecord::LogSubscriber.send(:include, LogSubscriber)
      ActiveRecord::Persistence.send(:include, Persistence)
      ActiveRecord::Locking::Optimistic.send(:include, LockingOptimistic)
      ActiveRecord::Relation.send(:include, CleverLoad, Relation)
      ActiveRecord::Migration.send(:include, ActiveRecord::Turntable::Migration)
      ActiveRecord::ConnectionAdapters::ConnectionHandler.instance_exec do
        include ConnectionHandlerExtension
      end
      ActiveRecord::Associations::Preloader::Association.send(:include, AssociationPreloader)
      ActiveRecord::Associations::Association.send(:include, Association)
      require 'active_record/turntable/active_record_ext/fixtures'
      require 'active_record/turntable/active_record_ext/migration_proxy'
      require 'active_record/turntable/active_record_ext/activerecord_import_ext'
    end
  end
end
