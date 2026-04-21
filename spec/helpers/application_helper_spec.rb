require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#chat_read_receipt_text" do
    it "keeps the seen receipt visible after a newer outgoing message is sent" do
      current_user = create(:user)
      other_user = create(:user, share_read_receipts: true)
      conversation = Conversation.create!
      create(:conversation_participant, conversation: conversation, user: current_user, last_read_at: 5.minutes.ago)
      create(:conversation_participant, conversation: conversation, user: other_user, last_read_at: 2.minutes.ago)
      create(:message, conversation: conversation, user: current_user, created_at: 3.minutes.ago)
      create(:message, conversation: conversation, user: current_user, created_at: 1.minute.ago)

      expect(helper.chat_read_receipt_text(conversation, current_user, other_user)).to match(/^Seen /)
    end
  end
end
