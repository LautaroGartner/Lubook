FactoryBot.define do
  factory :conversation_participant do
    conversation
    user
    last_read_at { nil }
  end
end
