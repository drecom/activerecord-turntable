FactoryBot.define do
  factory :item do
    name { Faker::Food.name }
  end
end
