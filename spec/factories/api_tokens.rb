FactoryBot.define do
  factory :api_token do
    association :user
    name { "Test iPhone" }
    expires_at { 90.days.from_now }
    last_used_at { Time.current }

    transient do
      raw_token { SecureRandom.hex(32) }
    end

    token_digest { ApiToken.digest(raw_token) }

    after(:build) do |api_token, evaluator|
      api_token.define_singleton_method(:raw_token) { evaluator.raw_token }
    end
  end
end
