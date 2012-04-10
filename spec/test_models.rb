
class User < ActiveRecord::Base
  # shard by surrogate_key
  turntable :user_cluster, :id
  sequencer
  has_one  :user_status
  has_many :cards_user
end

class UserStatus < ActiveRecord::Base
  # shard by other key
  turntable :user_cluster, :user_id
  sequencer
  belongs_to :user
end

class Card < ActiveRecord::Base
  belongs_to :cards_user
end

class CardsUser < ActiveRecord::Base
  turntable :user_cluster, :user_id
  sequencer

  belongs_to :user
  belongs_to :card
end
