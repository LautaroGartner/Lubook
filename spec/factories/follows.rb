FactoryBot.define do
  factory :follow do
    association :requester, factory: :user
    association :receiver, factory: :user
    status { :pending }

    trait :accepted do
      status { :accepted }
    end
  end
end
