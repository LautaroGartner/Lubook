FactoryBot.define do
  factory :comment do
    user
    post
    body { Faker::Lorem.sentence }
  end
end
