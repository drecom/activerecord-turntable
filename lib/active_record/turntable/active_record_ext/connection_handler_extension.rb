module ActiveRecord::Turntable
  module ActiveRecordExt
    module ConnectionHandlerExtension

      private

        # @note Override not to establish_connection destroy existing connection pool proxy object
        def pool_for_with_turntable(owner)
          owner_to_pool.fetch(owner.name) {
            if ancestor_pool = pool_from_any_process_for(owner)
              if ancestor_pool.is_a?(ActiveRecord::ConnectionAdapters::ConnectionPool)
                # A connection was established in an ancestor process that must have
                # subsequently forked. We can't reuse the connection, but we can copy
                # the specification and establish a new connection with it.
                establish_connection owner, ancestor_pool.spec
              else
                # Use same PoolProxy object
                owner_to_pool[owner.name] = ancestor_pool
              end
            else
              owner_to_pool[owner.name] = nil
            end
          }
        end
    end
  end
end
