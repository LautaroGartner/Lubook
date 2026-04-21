require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(2000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:post) }
    it { is_expected.to belong_to(:parent).class_name("Comment").optional }
    it { is_expected.to have_many(:likes) }
  end

  describe "touching the post" do
    it "updates the post's updated_at when created" do
      post = create(:post)
      original_updated_at = post.updated_at
      travel 1.minute do
        create(:comment, post: post)
        expect(post.reload.updated_at).to be > original_updated_at
      end
    end
  end

  describe "notifications" do
    it "notifies the post author for a top-level comment" do
      post = create(:post)
      commenter = create(:user)

      expect {
        create(:comment, post: post, user: commenter)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.recipient).to eq(post.user)
      expect(notification.action).to eq("comment")
    end

    it "notifies the parent comment author for a reply" do
      root_comment = create(:comment)
      replier = create(:user)

      expect {
        create(:comment, post: root_comment.post, parent: root_comment, user: replier)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.recipient).to eq(root_comment.user)
      expect(notification.action).to eq("reply")
    end
  end

  describe "#thread_root_id" do
    it "returns the top-level parent for nested replies" do
      root_comment = create(:comment)
      reply = create(:comment, post: root_comment.post, parent: root_comment)
      nested_reply = create(:comment, post: root_comment.post, parent: reply)

      expect(root_comment.thread_root_id).to eq(root_comment.id)
      expect(reply.thread_root_id).to eq(root_comment.id)
      expect(nested_reply.thread_root_id).to eq(root_comment.id)
    end
  end

  describe "#reply_target_user" do
    it "finds the transient reply target user" do
      target_user = create(:user)
      comment = build(:comment, reply_target_user_id: target_user.id)

      expect(comment.reply_target_user).to eq(target_user)
    end
  end
end
