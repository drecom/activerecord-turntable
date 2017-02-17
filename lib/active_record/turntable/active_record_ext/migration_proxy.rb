require "active_record/migration"

module ActiveRecord
  class MigrationProxy
    delegate :target_shard?, to: :migration
  end
end
