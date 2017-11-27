module ActiveRecord::Turntable
  class SeqShard < Shard
    private

      def create_connection_class
        klass = connection_class_instance
        klass.remove_connection
        klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:seq][name].with_indifferent_access
        klass
      end
  end
end
