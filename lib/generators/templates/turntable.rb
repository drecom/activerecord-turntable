cluster :user_cluster do
  algorithm :range_bsearch

  sequencer :user_seq, :mysql, connection: :user_seq

  shard      0...20_000,     to: :user_shard_1
  shard 20_000...40_000,     to: :user_shard_2
  shard 40_000...60_000,     to: :user_shard_1
  shard 60_000...80_000,     to: :user_shard_2
  shard 80_000...10_000_000, to: :user_shard_3
end

cluster :event_cluster do
  algorithm :range_bsearch

  sequencer :user_seq, :mysql, connection: :user_seq

  shard      0...20_000,     to: :user_shard_4
  shard 20_000...40_000,     to: :user_shard_5
  shard 40_000...60_000,     to: :user_shard_4
  shard 60_000...80_000,     to: :user_shard_5
  shard 80_000...10_000_000, to: :user_shard_6
end

cluster :mod_cluster do
  algorithm :modulo

  sequencer :user_seq, :mysql, connection: :user_seq

  shard      0...20_000,     to: :user_shard_1
  shard 20_000...40_000,     to: :user_shard_2
  shard 40_000...60_000,     to: :user_shard_1
  shard 60_000...80_000,     to: :user_shard_2
  shard 80_000...10_000_000, to: :user_shard_3
end

cluster :mysql_mod_cluster do
  algorithm :modulo

  sequencer :user_seq, :mysql, connection: :user_seq

  shard      0...20_000,     to: :user_shard_1
  shard 20_000...40_000,     to: :user_shard_2
  shard 40_000...60_000,     to: :user_shard_1
  shard 60_000...80_000,     to: :user_shard_2
  shard 80_000...10_000_000, to: :user_shard_3
end

raise_on_not_specified_shard_query false
raise_on_not_specified_shard_update false
