module ActiveRecord::Turntable
  class SeqShard < Shard
    def initialize(name = defined?(Rails) ? Rails.env : "development")
      super(nil, name)
    end

    def support_slave?
      false
    end

    private

      def create_connection_class
        klass = connection_class_instance
        klass.remove_connection
        klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:seq][name].with_indifferent_access
        klass
      end
  end
end
