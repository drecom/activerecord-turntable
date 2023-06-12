module ActiveRecord::Turntable
  class SeqShard < Shard
    def initialize(name = defined?(Rails) ? Rails.env : "development")
      super(nil, name)
    end

    def support_slave?
      false
    end

    private

      def connection_class_instance
        if Connections.const_defined?(name.classify)
          klass = Connections.const_get(name.classify)
        else
          klass = Class.new(ActiveRecord::Base)
          Connections.const_set(name.classify, klass)
          klass.abstract_class = true
          if Util.ar61_or_later?
            klass.establish_connection ActiveRecord::Base.connection_pool.db_config.configuration_hash[:seq][name].with_indifferent_access
          else
            klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:seq][name].with_indifferent_access
          end
        end
        klass
      end
  end
end
