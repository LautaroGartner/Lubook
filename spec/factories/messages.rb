FactoryBot.define do
  factory :message do
    conversation
    user
    body { Faker::Lorem.sentence }
  end
end
