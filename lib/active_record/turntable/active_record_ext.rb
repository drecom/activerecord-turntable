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
      ActiveRecord::ConnectionAdapters::AbstractAdapter.include(Sequencer)
      ActiveRecord::ConnectionAdapters::AbstractAdapter.include(AbstractAdapter)
      ActiveRecord::LogSubscriber.include(LogSubscriber)
      ActiveRecord::Persistence.include(Persistence)
      ActiveRecord::Locking::Optimistic.include(LockingOptimistic)
      ActiveRecord::Relation.include(CleverLoad, Relation)
      ActiveRecord::Migration.include(ActiveRecord::Turntable::Migration)
      ActiveRecord::ConnectionAdapters::ConnectionHandler.instance_exec do
        include ConnectionHandlerExtension
      end
      ActiveRecord::Associations::Preloader::Association.prepend(AssociationPreloader)
      ActiveRecord::Associations::Association.include(Association)
      require "active_record/turntable/active_record_ext/fixtures"
      require "active_record/turntable/active_record_ext/migration_proxy"
      require "active_record/turntable/active_record_ext/activerecord_import_ext"
      require "active_record/turntable/active_record_ext/acts_as_archive_extension"
    end
  end
end
