FactoryGirl.define do
  factory :user_status do
    hp 10
    mp 10

    trait :created_yesterday do
      created_at 1.day.ago
      updated_at 1.day.ago
    end
  end
end
