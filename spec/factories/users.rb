FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "testpassword123" }
    password_confirmation { "testpassword123" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
