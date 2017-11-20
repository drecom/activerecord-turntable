module ActiveRecord::Turntable
  class SequencerRegistry
    attr_reader :sequencers
    alias_method :all, :sequencers

    def initialize
      @sequencers = {}.with_indifferent_access
      @cluster_sequencers = {}.with_indifferent_access
    end

    def add(name, type, options, cluster)
      # TODO: Warn if defined the same name sequencer already.
      sequencer = (@sequencers[name] ||= Sequencer.class_for(type).new(options))
      @cluster_sequencers[cluster] ||= {}.with_indifferent_access
      @cluster_sequencers[cluster][name] ||= sequencer
    end

    def release!
      @sequencers.each(&:release!)
    end

    def [](name)
      @sequencers[name]
    end

    def cluster_sequencers(cluster)
      @cluster_sequencers[cluster]
    end
  end
end
