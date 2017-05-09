class UserItemHistory < ActiveRecord::Base
  turntable :user_cluster, :user_id
  sequencer :user_seq

  belongs_to :user
  belongs_to :user_item
end
