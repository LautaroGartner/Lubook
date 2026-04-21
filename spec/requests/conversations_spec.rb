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

  describe "POST /conversations" do
    it "starts or reuses a conversation and redirects to it" do
      post conversations_path, params: { user_id: connected_user.id }

      conversation = Conversation.last
      expect(response).to redirect_to(conversation_path(conversation))
      expect(conversation.participants).to include(user, connected_user)
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

  describe "GET /conversations/:id/presence" do
    it "renders a turbo stream update for chat presence" do
      conversation = Conversation.create!
      create(:conversation_participant, conversation: conversation, user: user)
      create(:conversation_participant, conversation: conversation, user: connected_user)

      get presence_conversation_path(conversation), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("conversation_presence")
    end
  end
end
