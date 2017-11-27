require "active_record/turntable/configuration"

module ActiveRecord::Turntable
  class Configuration
    class DSL
      attr_reader :configuration

      def initialize(configuration = Configuration.new)
        @configuration = configuration
      end

      def cluster(name, &block)
        cluster_dsl = ClusterDSL.new(configuration).tap { |dsl| dsl.instance_exec(&block) }
        configuration.clusters[name] = cluster_dsl.cluster
      end

      GLOBAL_SETTINGS_KEYS = %w(
        raise_on_not_specified_shard_query
        raise_on_not_specified_shard_update
      ).freeze

      GLOBAL_SETTINGS_KEYS.each do |k|
        define_method(k) do |value|
          configuration.send("#{k}=", value)
        end
      end

      def global_settings_keys
        GLOBAL_SETTINGS_KEYS
      end

      class ClusterDSL < DSL
        attr_reader :sequencers

        def initialize(configuration)
          super
          @algorithm = Algorithm.class_for("range").new(nil)
          @shard_settings = []
          @sequencer_settings = []
        end

        def cluster
          Cluster.build(configuration.sequencer_registry) do |c|
            c.algorithm = @algorithm
            @shard_settings.each do |setting|
              c.shard_registry.add(setting)
            end
            @sequencer_settings.each do |name, type, options|
              c.sequencer_registry.add(name, type, options, c)
            end
          end
        end

        def algorithm(type, options = {})
          @algorithm = Algorithm.class_for(type.to_s).new(options)
        end

        def sequencer(sequencer_name, type, options = {})
          @sequencer_settings << [sequencer_name.to_s, type.to_s, options]
        end

        ShardSetting = Struct.new(:name, :range, :slaves) do
          def range
            case self[:range]
            when Integer
              self[:range]..self[:range]
            else
              self[:range]
            end
          end
        end

        def shard(range,  slaves: [], to:)
          @shard_settings << ShardSetting.new(to.to_s, range, slaves.map(&:to_s))
        end
      end
    end
  end
end
