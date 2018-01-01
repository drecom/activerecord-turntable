FactoryBot.define do
  factory :user_item do
    item

    trait :with_user_item_history do
      after(:build) do |user_item, _evaluator|
        create(:user_item_history, user: user_item.user, user_item: user_item)
      end
    end

    trait :with_user_event_history do
      after(:build) do |user_item, _evaluator|
        create(:user_event_history, user: user_item.user, user_item: user_item, event_user_id: user_item.user_id)
      end
    end
  end
end
