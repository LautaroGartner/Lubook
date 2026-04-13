FactoryBot.define do
  factory :profile do
    user { nil }
    display_name { "MyString" }
    bio { "MyText" }
    location { "MyString" }
  end
end
