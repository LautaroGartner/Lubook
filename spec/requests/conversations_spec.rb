require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:user) { create(:user) }
  let(:connected_user) { create(:user) }

  before do
    sign_in user
    create(:follow, requester: user, receiver: connected_user, status: :accepted)
  end

  describe "GET /conversations" do
    it "shows the chat finder for connected users" do
      get conversations_path

      expect(response.body).to include("Find someone to message")
      expect(response.body).to include(connected_user.username)
      expect(response.body).to include("Message")
    end
  end

  describe "GET /conversations/:id" do
    it "shows the active chat without the finder panel" do
      conversation = Conversation.create!
      create(:conversation_participant, conversation: conversation, user: user)
      create(:conversation_participant, conversation: conversation, user: connected_user)

      get conversation_path(conversation)

      expect(response.body).to include("Back to chats")
      expect(response.body).not_to include("Find someone to message")
    end
  end
end
