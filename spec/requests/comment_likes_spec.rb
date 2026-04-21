require "rails_helper"

RSpec.describe "Comment likes", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }
  let(:comment) { create(:comment, post: post_record) }

  before { sign_in user }

  it "likes a comment over turbo stream without rendering errors" do
    expect {
      post comment_like_path(comment), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    }.to change(Like, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("post_comments_section")
  end

  it "unlikes a comment over turbo stream without rendering errors" do
    create(:like, likeable: comment, user: user)

    expect {
      delete comment_like_path(comment), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    }.to change(Like, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("post_comments_section")
  end

  it "does not expand hidden replies unless the thread was already expanded" do
    root_comment = create(:comment, post: post_record)
    reply_one = create(:comment, post: post_record, parent: root_comment)
    create(:comment, post: post_record, parent: root_comment)
    create(:comment, post: post_record, parent: root_comment)

    post comment_like_path(reply_one), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    expect(response.body).to include("View 1 more reply")
    expect(response.body).to include('data-comment-thread-target="hiddenReplies" class="hidden ')
  end
end
