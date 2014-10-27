module ActiveRecord::Turntable
  module ActiveRecordExt
    module ConnectionHandlerExtension
      extend ActiveSupport::Concern

      included do
        alias_method_chain :pool_for, :turntable
      end

      private

      def pool_for_with_turntable(owner)
        owner_to_pool.fetch(owner.name) {
          if ancestor_pool = pool_from_any_process_for(owner)
            if ancestor_pool.is_a?(ActiveRecord::Turntable::PoolProxy)
              # Use same PoolProxy object
              owner_to_pool[owner.name] = ancestor_pool
            else
              # A connection was established in an ancestor process that must have
              # subsequently forked. We can't reuse the connection, but we can copy
              # the specification and establish a new connection with it.
              establish_connection owner, ancestor_pool.spec
            end
          else
            owner_to_pool[owner.name] = nil
          end
        }
      end
    end
  end
end
