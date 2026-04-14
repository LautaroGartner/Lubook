require "rails_helper"

RSpec.describe "Follows", type: :request do
  let(:requester) { create(:user) }
  let(:receiver) { create(:user) }

  describe "POST /follows" do
    before { sign_in requester }

    it "creates a pending follow request" do
      expect {
        post follows_path, params: { receiver_id: receiver.id }
      }.to change(Follow, :count).by(1)
      expect(Follow.last).to be_pending
    end

    it "cannot create a follow to self" do
      expect {
        post follows_path, params: { receiver_id: requester.id }
      }.not_to change(Follow, :count)
    end
  end

  describe "POST /follows/:id/accept" do
    let!(:follow) { create(:follow, requester: requester, receiver: receiver) }

    it "allows the receiver to accept" do
      sign_in receiver
      patch accept_follow_path(follow)
      expect(follow.reload).to be_accepted
    end

    it "forbids the requester from accepting their own request" do
      sign_in requester
      patch accept_follow_path(follow)
      expect(follow.reload).to be_pending
    end
  end
end
