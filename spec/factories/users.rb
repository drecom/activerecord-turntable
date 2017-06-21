FactoryGirl.define do
  factory :user do
    sequence(:id, 1)
    nickname { Faker::Name.name }

    after(:build) do |user, _evaluator|
      create(:user_profile, user: user)
    end

    trait :with_user_items do
      transient do
        user_items_count 10
      end

      after(:build) do |user, evaluator|
        create_list(:user_item, evaluator.user_items_count, user: user)
      end
    end

    trait :in_shard1 do
      sequence(:id, 1) { |i| i }
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
