require "rails_helper"

RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /posts/:id" do
    let(:post_record) { create(:post, user: user) }

    it "requires authentication" do
      get post_path(post_record)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders the post when signed in" do
      sign_in user
      get post_path(post_record)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post_record.body)
    end
  end

  describe "POST /posts" do
it "creates a post with valid params when signed in" do
      sign_in user
      expect {
        post posts_path, params: { post: { body: "Hello Lubook" } }
      }.to change(Post, :count).by(1)
      expect(response).to redirect_to(root_path)
    end
    it "does not create a post with blank body" do
      sign_in user
      expect {
        post posts_path, params: { post: { body: "" } }
      }.not_to change(Post, :count)
    end
  end

  describe "PATCH /posts/:id" do
    let!(:post_record) { create(:post, user: user, body: "original") }

    it "allows the author to edit" do
      sign_in user
      patch post_path(post_record), params: { post: { body: "edited" } }
      expect(post_record.reload.body).to eq("edited")
    end

    it "forbids other users from editing" do
      sign_in other_user
      patch post_path(post_record), params: { post: { body: "hacked" } }
      expect(post_record.reload.body).to eq("original")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /posts/:id" do
    let!(:post_record) { create(:post, user: user) }

    it "allows the author to delete" do
      sign_in user
      expect { delete post_path(post_record) }.to change(Post, :count).by(-1)
    end

    it "redirects turbo delete back to the feed instead of the deleted post" do
      sign_in user
      delete post_path(post_record), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to redirect_to(root_path)
    end

    it "forbids other users from deleting" do
      sign_in other_user
      expect { delete post_path(post_record) }.not_to change(Post, :count)
    end
  end
end
