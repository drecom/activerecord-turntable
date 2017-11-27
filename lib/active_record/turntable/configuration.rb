module ActiveRecord::Turntable
  class Configuration
    extend ActiveSupport::Autoload
    autoload :DSL
    autoload :Loader

    attr_reader :cluster_registry, :sequencer_registry
    attr_accessor :raise_on_not_specified_shard_query,
                  :raise_on_not_specified_shard_update
    alias_method :configure, :instance_exec
    alias_method :clusters, :cluster_registry

    def initialize
      @cluster_registry = ClusterRegistry.new
      @sequencer_registry = SequencerRegistry.new
    end

    def cluster(name)
      cluster_registry[name]
    end

    def sequencers
      sequencer_registry.sequencers
    end

    def sequencer(name)
      sequencer_registry[name]
    end

    def release!
      cluster_registry.release!
      sequencer_registry.release!
    end

    def self.configure(&block)
      new.tap { |c| c.configure(&block) }
    end

    def self.load(path, env)
      case File.extname(path)
      when ".yml"
        Loader::YAML.load(path, env)
      when ".rb"
        Loader::DSL.load(path)
      else
        raise InvalidConfigurationError, "Invalid configuration file path: #{path}"
      end
    end
  end
end
