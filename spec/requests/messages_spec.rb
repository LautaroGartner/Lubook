require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:conversation) do
    Conversation.create!.tap do |conv|
      create(:conversation_participant, conversation: conv, user: user, last_read_at: 10.minutes.ago)
      create(:conversation_participant, conversation: conv, user: other_user, last_read_at: 10.minutes.ago)
    end
  end

  before { sign_in user }

  describe "POST /conversations/:conversation_id/messages" do
    it "appends a message over turbo stream without redirecting" do
      expect {
        post conversation_messages_path(conversation),
             params: { message: { body: "hello there" } },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change(Message, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("conversation_messages")
      expect(response.body).to include("message_form")
    end
  end

  describe "PATCH /conversations/:id/read" do
    it "marks the conversation as read for the current user" do
      patch read_conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      expect(conversation.conversation_participants.find_by(user: user).reload.last_read_at).to be_present
    end
  end
end
