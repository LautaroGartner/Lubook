FactoryBot.define do
  factory :notification do
    recipient { association :user }
    actor { association :user }
    action { "comment" }
    association :notifiable, factory: :comment
    read_at { nil }
  end
end
