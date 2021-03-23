module ActiveRecord::Turntable
  module ActiveRecordExt
    module QueryCache
      def self.prepended(klass)
        class << klass
          prepend ClassMethods.compatible_module
        end
      end

      module ClassMethods
        extend Compatibility

        module V6_0
        end

        module V5_2
        end

        module V5_1
          def run
            result = super

            pools = ActiveRecord::Base.turntable_pool_list
            pools.each do |pool|
              pool.enable_query_cache!
            end

            [*result, pools]
          end

          def complete(state)
            caching_pool, caching_was_enabled, turntable_pools = state
            super([caching_pool, caching_was_enabled])

            turntable_pools.each do |pool|
              pool.disable_query_cache! unless caching_was_enabled
            end
          end
        end

        module V5_0_1
          def run
            result = super

            pools = ActiveRecord::Base.turntable_pool_list
            pools.each do |pool|
              pool.enable_query_cache!
            end

            [*result, pools]
          end

          def complete(state)
            caching_pool, caching_was_enabled, connection_id, turntable_pools = state
            super([caching_pool, caching_was_enabled, connection_id])

            turntable_pools.each do |pool|
              pool.disable_query_cache! unless caching_was_enabled
            end
          end
        end

        module V5_0
          def run
            result = super

            pools = ActiveRecord::Base.turntable_pool_list
            pools.each do |k|
              k.connection.enable_query_cache!
            end

            result
          end

          def complete(state)
            enabled, _connection_id = state
            super

            klasses = ActiveRecord::Base.turntable_pool_list
            klasses.each do |k|
              k.connection.clear_query_cache
              k.connection.disable_query_cache! unless enabled
            end
          end
        end
      end

      def self.install_turntable_executor_hooks(executor = ActiveSupport::Executor)
        return if Util.ar_version_equals_or_later?("5.0.1")

        executor.to_complete do
          klasses = ActiveRecord::Base.turntable_connection_classes
          klasses.each do |k|
            unless k.connected? && k.connection.transaction_open?
              k.clear_active_connections!
            end
          end
        end
      end
    end
  end
end
