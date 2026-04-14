FactoryBot.define do
  factory :post do
    user
    body { Faker::Lorem.paragraph(sentence_count: 3) }
  end
end
