require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:action).in_array(Notification::ACTIONS) }
  end

  describe "#message" do
    it "formats a reply message" do
      notification = build(:notification, action: "reply")

      expect(notification.message).to include("replied to your comment")
    end
  end
end
