require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe ".direct_between!" do
    it "reuses an existing direct conversation" do
      user_a = create(:user)
      user_b = create(:user)
      conversation = Conversation.create!
      create(:conversation_participant, conversation: conversation, user: user_a)
      create(:conversation_participant, conversation: conversation, user: user_b)

      found = described_class.direct_between!(user_a, user_b)

      expect(found).to eq(conversation)
      expect(described_class.count).to eq(1)
    end
  end
end
