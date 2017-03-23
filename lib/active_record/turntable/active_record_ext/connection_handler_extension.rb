module ActiveRecord::Turntable
  module ActiveRecordExt
    module ConnectionHandlerExtension
      # @note Override not to establish_connection destroy existing connection pool proxy object
      def retrieve_connection_pool(spec_name)
        owner_to_pool.fetch(spec_name) do
          # Check if a connection was previously established in an ancestor process,
          # which may have been forked.
          if ancestor_pool = pool_from_any_process_for(spec_name)
            if ancestor_pool.is_a?(ActiveRecord::ConnectionAdapters::ConnectionPool)
              # A connection was established in an ancestor process that must have
              # subsequently forked. We can't reuse the connection, but we can copy
              # the specification and establish a new connection with it.
              spec = ancestor_pool.spec
              spec = spec.to_hash if spec.respond_to?(:to_hash)
              establish_connection(spec).tap do |pool|
                pool.schema_cache = ancestor_pool.schema_cache if ancestor_pool.schema_cache
              end
            else
              # Use same PoolProxy object
              owner_to_pool[spec_name] = ancestor_pool
            end
          else
            owner_to_pool[spec_name] = nil
          end
        end
      end
    end
  end
end
