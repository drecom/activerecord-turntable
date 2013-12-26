#
#= ActiveRecord::Turntable
#
# ActiveRecord Sharding Plugin
#
require 'active_record/turntable/version'
require 'active_record'
require 'active_record/fixtures'
require 'active_support/concern'
require 'active_record/turntable/error'
require 'logger'
require 'singleton'

module ActiveRecord::Turntable
  extend ActiveSupport::Concern

  autoload :ActiveRecordExt, 'active_record/turntable/active_record_ext'
  autoload :Algorithm, 'active_record/turntable/algorithm'
  autoload :Base, 'active_record/turntable/base'
  autoload :Cluster, 'active_record/turntable/cluster'
  autoload :Config, 'active_record/turntable/config'
  autoload :ConnectionProxy, 'active_record/turntable/connection_proxy'
  autoload :Helpers, 'active_record/turntable/helpers'
  autoload :MasterShard, 'active_record/turntable/master_shard'
  autoload :Migration, 'active_record/turntable/migration'
  autoload :Mixer, 'active_record/turntable/mixer'
  autoload :PoolProxy, 'active_record/turntable/pool_proxy'
  autoload :Rack, 'active_record/turntable/rack'
  autoload :SeqShard, 'active_record/turntable/seq_shard'
  autoload :Sequencer, 'active_record/turntable/sequencer'
  autoload :Shard, 'active_record/turntable/shard'

  included do
    include ActiveRecordExt
    include Base
  end

  module ClassMethods
    DEFAULT_PATH = File.dirname(File.dirname(__FILE__))

    def turntable_config_file
      @@turntable_config_file ||=
        File.join(defined?(::Rails) ?
                   ::Rails.root.to_s : DEFAULT_PATH, 'config/turntable.yml')
    end

    def turntable_config_file=(filename)
      @@turntable_config_file = filename
    end

    def turntable_config
      ActiveRecord::Turntable::Config.instance
    end
  end

  require "active_record/turntable/railtie" if defined?(Rails)
end
