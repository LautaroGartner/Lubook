require "rails_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:api_token) { create(:api_token, user: user) }
  let!(:post_record) { create(:post, user: user, body: "API post") }
  let!(:comment) { create(:comment, post: post_record, user: user, body: "First comment") }

  it "returns a post and its comments" do
    get "/api/v1/posts/#{post_record.id}", headers: {
      "Authorization" => "Bearer #{api_token.raw_token}"
    }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)

    expect(json.dig("post", "body")).to eq("API post")
    expect(json.fetch("comments").map { |entry| entry.fetch("body") }).to include("First comment")
  end
end
