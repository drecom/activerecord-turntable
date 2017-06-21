class UserProfile < ActiveRecord::Base
  # shard by other key
  turntable :user_cluster, :user_id
  sequencer :user_seq
  belongs_to :user
  serialize :data, JSON
end
