RSpec::Matchers.define :permit_actions do |actions|
  match do |policy|
    actions.all? { |action| policy.public_send("#{action}?") }
  end
  failure_message do |policy|
    forbidden = actions.reject { |action| policy.public_send("#{action}?") }
    "expected #{policy.class} to permit #{actions}, but forbade #{forbidden}"
  end
end

RSpec::Matchers.define :forbid_actions do |actions|
  match do |policy|
    actions.none? { |action| policy.public_send("#{action}?") }
  end
  failure_message do |policy|
    permitted = actions.select { |action| policy.public_send("#{action}?") }
    "expected #{policy.class} to forbid #{actions}, but permitted #{permitted}"
  end
end
