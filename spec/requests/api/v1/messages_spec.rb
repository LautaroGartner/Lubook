require "rails_helper"

RSpec.describe "Api::V1::Messages", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:other_user) { create(:user, confirmed_at: Time.current) }
  let!(:conversation) { Conversation.direct_between!(user, other_user) }
  let!(:api_token) { create(:api_token, user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_token.raw_token}" } }

  it "creates a message" do
    expect {
      post "/api/v1/conversations/#{conversation.id}/messages",
           params: { message: { body: "native hello" } },
           headers: headers
    }.to change(Message, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body).dig("message", "body")).to eq("native hello")
  end
end
