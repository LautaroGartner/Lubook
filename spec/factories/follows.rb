FactoryBot.define do
  factory :follow do
    requester { nil }
    receiver { nil }
    status { 1 }
  end
end
