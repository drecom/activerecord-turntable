FactoryBot.define do
  factory :user_profile do
    birthday { Faker::Date.birthday }
    published { false }
    user

    trait :created_yesterday do
      created_at { 1.day.ago }
      updated_at { 1.day.ago }
    end

    trait :published do
      published { true }
    end
  end
end
