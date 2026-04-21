require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }

  before { sign_in user }

  describe "POST /posts/:post_id/comments" do
    it "creates a top-level comment over turbo stream without redirecting" do
      expect {
        post post_comments_path(post_record),
             params: { comment: { body: "Fresh comment" } },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("post_comments_section")
      expect(response.body).to include("Fresh comment")
    end

    it "creates a reply over turbo stream without redirecting" do
      parent_comment = create(:comment, post: post_record)

      expect {
        post post_comments_path(post_record),
             params: { comment: { body: "Reply here", parent_id: parent_comment.id } },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(Comment.last.parent).to eq(parent_comment)
    end

    it "stores a reply-to-reply at the bottom of the same top-level thread without forcing a mention" do
      root_comment = create(:comment, post: post_record, body: "Root")
      reply = create(:comment, post: post_record, parent: root_comment, body: "First reply")

      post post_comments_path(post_record),
           params: { comment: { body: "Following up", parent_id: reply.id, reply_target_user_id: reply.user_id } },
           headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      created_reply = Comment.last
      expect(created_reply.parent).to eq(root_comment)
      expect(created_reply.body).to eq("Following up")
    end

    it "renders nested replies inside the same top-level thread" do
      root_comment = create(:comment, post: post_record, body: "Root")
      reply = create(:comment, post: post_record, parent: root_comment, body: "Reply one")
      create(:comment, post: post_record, parent: reply, body: "Reply two")
      create(:comment, post: post_record, parent: reply, body: "Reply three")

      get post_path(post_record)

      expect(response.body.scan("View 1 more reply").size).to eq(1)
      expect(response.body).to include("Reply one")
      expect(response.body).to include("Reply two")
      expect(response.body).not_to include("ml-6")
    end
  end

  describe "DELETE /comments/:id" do
    it "removes a comment over turbo stream without redirecting" do
      comment = create(:comment, post: post_record, user: user)

      expect {
        delete comment_path(comment), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      }.to change(Comment, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("post_comments_section")
    end
  end
end
