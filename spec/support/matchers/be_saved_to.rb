RSpec::Matchers.define :be_saved_to do |shard|
  match do |actual|
    persisted_actual = actual.with_shard(shard) { actual.class.find(actual.id) }
    persisted_actual && actual == persisted_actual
  end
end
