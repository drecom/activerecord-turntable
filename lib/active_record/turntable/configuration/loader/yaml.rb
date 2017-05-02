module ActiveRecord::Turntable
  class Configuration
    class Loader::YAML
      attr_reader :path, :configuration, :dsl

      def initialize(path, configuration = Configuration.new)
        @path = path
        @configuration = configuration
        @dsl = DSL.new(@configuration)
      end

      def self.load(path, env, configuration = Configuration.new)
        new(path, configuration).load(env)
      end

      def load(env)
        yaml = YAML.load(ERB.new(IO.read(path)).result).with_indifferent_access[env]
        load_clusters(yaml[:clusters])
        load_global_settings(yaml)

        configuration
      end

      private

        def load_clusters(clusters_config)
          clusters_config.each do |cluster_name, conf|
            @dsl.cluster(cluster_name) do
              algorithm conf[:algorithm] if conf[:algorithm]

              if conf[:seq]
                conf[:seq].each do |sequence_name, sequence_conf|
                  sequencer(sequence_name, (sequence_conf[:type] || :mysql), sequence_conf)
                end
              end

              if conf[:shards]
                current_lower_limit = 1
                conf[:shards].each do |shard_conf|
                  upper_limit = if shard_conf.has_key?(:less_than)
                                  shard_conf[:less_than] - 1
                                else
                                  current_lower_limit
                                end
                  shard current_lower_limit..upper_limit, to: shard_conf[:connection], slaves: Array.wrap(shard_conf[:slaves])
                  current_lower_limit = upper_limit + 1
                end
              end
            end
          end
        end

        def load_global_settings(yaml)
          yaml.each do |k, v|
            if @dsl.global_settings_keys.include?(k)
              @dsl.send(k, v)
            end
          end
        end
    end
  end
end
