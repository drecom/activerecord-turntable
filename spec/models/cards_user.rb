class CardsUser < ActiveRecord::Base
  turntable :user_cluster, :user_id
  sequencer :user_seq

  belongs_to :user
  belongs_to :card
  has_many :cards_users_histories
  has_many :events_users_histories
  has_many :events_users_histories_with_foreign_shard_key, class_name: "EventsUsersHistory", foreign_shard_key: :user_id
end
