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
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :ActiveRecordExt
    autoload :Algorithm
    autoload :Base
    autoload :Cluster
    autoload :ClusterHelperMethods
    autoload :Config
    autoload :ConnectionProxy
    autoload :MasterShard
    autoload :Migration
    autoload :Mixer
    autoload :PoolProxy
    autoload :Shard
    autoload :SeqShard
    autoload :Sequencer
  end
  autoload :Rack
  autoload :Helpers

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

  def self.rails4?
    ActiveRecord::VERSION::MAJOR == 4
  end

  def self.rails41_later?
    rails4? && ActiveRecord::VERSION::MINOR >= 1
  end

  require "active_record/turntable/railtie" if defined?(Rails)
end
