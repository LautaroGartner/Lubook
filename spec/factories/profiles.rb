FactoryBot.define do
  factory :profile do
    user
    display_name { Faker::Name.name }
    bio { Faker::Lorem.sentence }
    location { Faker::Address.city }
  end
end
