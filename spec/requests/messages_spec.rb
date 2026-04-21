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

    it "allows sending a photo without text" do
      expect {
        post conversation_messages_path(conversation),
             params: {
               message: {
                 body: "",
                 image: Rack::Test::UploadedFile.new(
                   Rails.root.join("spec/fixtures/files/chat-image.svg"),
                   "image/svg+xml"
                 )
               }
             },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change(Message, :count).by(1)

      expect(Message.last.image).to be_attached
      expect(response).to have_http_status(:ok)
    end

    it "allows replying to a specific message in the same conversation" do
      original_message = create(:message, conversation: conversation, user: other_user, body: "original")

      expect {
        post conversation_messages_path(conversation),
             params: { message: { body: "replying", reply_to_message_id: original_message.id } },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change(Message, :count).by(1)

      expect(Message.last.reply_to_message).to eq(original_message)
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
