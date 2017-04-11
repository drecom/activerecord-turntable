FactoryGirl.define do
  factory :user do
    sequence(:id, 1)
    sequence(:nickname) { |i| "nickname-#{i}" }

    after(:build) do |user, _evaluator|
      create(:user_status, user: user)
      create(:cards_user, user: user)
    end

    trait :in_shard2 do
      sequence(:id, 20001) { |i| i }
    end

    trait :in_shard3 do
      sequence(:id, 80001) { |i| i }
    end

    trait :created_yesterday do
      created_at 1.day.ago
      updated_at 1.day.ago
    end
  end

  factory :user_with_callbacks
end
