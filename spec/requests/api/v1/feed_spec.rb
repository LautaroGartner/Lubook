require "rails_helper"

RSpec.describe "Api::V1::Feed", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:followed_user) { create(:user, confirmed_at: Time.current) }
  let!(:follow) { create(:follow, requester: user, receiver: followed_user, status: :accepted) }
  let!(:own_post) { create(:post, user: user, body: "My post") }
  let!(:followed_post) { create(:post, user: followed_user, body: "Followed post") }
  let!(:stranger_post) { create(:post, body: "Hidden post") }
  let!(:api_token) { create(:api_token, user: user) }

  it "requires a bearer token" do
    get "/api/v1/feed"

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns the signed-in user's feed" do
    get "/api/v1/feed", headers: {
      "Authorization" => "Bearer #{api_token.raw_token}"
    }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    post_bodies = json.fetch("posts").map { |post| post.fetch("body") }

    expect(post_bodies).to include("My post", "Followed post")
    expect(post_bodies).not_to include("Hidden post")
  end
end
