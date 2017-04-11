FactoryGirl.define do
  factory :user do
    sequence(:nickname) { |i| "nickname-#{i}" }

    trait :in_shard1 do
      sequence(:id, 1) { |i| i }
    end

    trait :in_shard2 do
      sequence(:id, 20001) { |i| i }
    end

    trait :in_shard3 do
      sequence(:id, 80001) { |i| i }
    end

    trait :one_day_ago do
      created_at 1.day.ago
      updated_at 1.day.ago
    end
  end
end
