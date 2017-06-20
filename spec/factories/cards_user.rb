FactoryGirl.define do
  factory :cards_user do
    card

    trait :with_cards_users_history do
      after(:build) do |cards_user, _evaluator|
        create(:cards_users_history, user: cards_user.user, cards_user: cards_user)
      end
    end

    trait :with_events_users_history do
      after(:build) do |cards_user, _evaluator|
        create(:events_users_history, user: cards_user.user, cards_user: cards_user, events_user_id: cards_user.user_id)
      end
    end
  end
end
