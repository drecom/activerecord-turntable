class UserItem < ActiveRecord::Base
  turntable :user_cluster, :user_id
  sequencer :user_seq

  belongs_to :user
  belongs_to :item
  has_many :user_item_histories
  has_many :user_event_histories
  has_many :user_event_histories_with_foreign_shard_key, class_name: "UserEventHistory", foreign_shard_key: :user_id
end
