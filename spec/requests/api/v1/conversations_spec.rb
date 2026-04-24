require "rails_helper"

RSpec.describe "Api::V1::Conversations", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:other_user) { create(:user, confirmed_at: Time.current) }
  let!(:follow) { create(:follow, requester: user, receiver: other_user, status: :accepted) }
  let!(:api_token) { create(:api_token, user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_token.raw_token}" } }

  describe "GET /api/v1/conversations" do
    it "returns the user's conversations" do
      conversation = Conversation.direct_between!(user, other_user)
      create(:message, conversation: conversation, user: other_user, body: "hey there")

      get "/api/v1/conversations", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("conversations").first.dig("latest_message", "body")).to eq("hey there")
    end
  end

  describe "POST /api/v1/conversations" do
    it "creates or reuses a conversation with a connected user" do
      post "/api/v1/conversations", params: { user_id: other_user.id }, headers: headers

      expect(response).to have_http_status(:created)
      expect(Conversation.last.participants).to include(user, other_user)
    end
  end

  describe "GET /api/v1/conversations/:id" do
    it "returns messages and marks the conversation as read" do
      conversation = Conversation.direct_between!(user, other_user)
      participant = conversation.participant_for(user)
      create(:message, conversation: conversation, user: other_user, body: "hello from web")

      get "/api/v1/conversations/#{conversation.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("messages").first.fetch("body")).to eq("hello from web")
      expect(participant.reload.last_read_at).to be_present
    end
  end
end
