require "rails_helper"

RSpec.describe "Api::V1 post interactions", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:api_token) { create(:api_token, user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_token.raw_token}" } }

  describe "POST /api/v1/posts" do
    it "creates a post" do
      expect {
        post "/api/v1/posts", params: { post: { body: "From native iOS" } }, headers: headers
      }.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("post", "body")).to eq("From native iOS")
    end
  end

  describe "POST /api/v1/posts/:post_id/comments" do
    let!(:post_record) { create(:post) }

    it "creates a comment" do
      expect {
        post "/api/v1/posts/#{post_record.id}/comments", params: { comment: { body: "Native comment" } }, headers: headers
      }.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("comment", "body")).to eq("Native comment")
    end
  end

  describe "POST /api/v1/posts/:post_id/like" do
    let!(:post_record) { create(:post) }

    it "likes and unlikes a post" do
      post "/api/v1/posts/#{post_record.id}/like", headers: headers
      expect(response).to have_http_status(:created)
      expect(post_record.reload.likes.count).to eq(1)

      delete "/api/v1/posts/#{post_record.id}/like", headers: headers
      expect(response).to have_http_status(:ok)
      expect(post_record.reload.likes.count).to eq(0)
    end
  end

  describe "POST /api/v1/comments/:comment_id/like" do
    let!(:comment) { create(:comment) }

    it "likes and unlikes a comment" do
      post "/api/v1/comments/#{comment.id}/like", headers: headers
      expect(response).to have_http_status(:created)
      expect(comment.reload.likes.count).to eq(1)

      delete "/api/v1/comments/#{comment.id}/like", headers: headers
      expect(response).to have_http_status(:ok)
      expect(comment.reload.likes.count).to eq(0)
    end
  end
end
