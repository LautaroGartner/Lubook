require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "DELETE /notifications/:id" do
    it "clears one notification" do
      notification = create(:notification, recipient: user)

      expect {
        delete notification_path(notification)
      }.to change(Notification, :count).by(-1)
    end
  end

  describe "GET /notifications/live" do
    it "renders a turbo stream update for the notifications badge" do
      create(:notification, recipient: user)

      get live_notifications_path, headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("notifications_badge")
      expect(response.body).to include("mobile_notifications_badge")
      expect(response.body).to include("mobile_menu_notifications_badge")
    end

    it "updates the notifications list when requested" do
      create(:notification, recipient: user)

      get live_notifications_path(include_list: true), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("notifications_list_container")
    end
  end

  describe "DELETE /notifications/clear" do
    it "clears all notifications for the current user" do
      create_list(:notification, 2, recipient: user)
      create(:notification)

      expect {
        delete clear_notifications_path
      }.to change(user.notifications, :count).from(2).to(0)
    end
  end

  describe "PATCH /follows/:id/accept from notifications" do
    it "accepts the request and clears the notification" do
      requester = create(:user)
      follow = create(:follow, requester: requester, receiver: user)
      notification = create(:notification,
                            recipient: user,
                            actor: requester,
                            action: "follow_request",
                            notifiable: follow)

      patch accept_follow_path(follow), params: { notification_id: notification.id }

      expect(follow.reload).to be_accepted
      expect(Notification.exists?(notification.id)).to be(false)
    end
  end
end
