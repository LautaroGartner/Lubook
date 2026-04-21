require "rails_helper"

RSpec.describe Message, type: :model do
  describe "validations" do
    it "allows an image without body text" do
      message = build(:message, body: "")
      message.image.attach(
        io: Rails.root.join("spec/fixtures/files/chat-image.svg").open,
        filename: "chat-image.svg",
        content_type: "image/svg+xml"
      )

      expect(message).to be_valid
    end

    it "requires either body text or an image" do
      message = build(:message, body: "")

      expect(message).not_to be_valid
      expect(message.errors[:base]).to include("Add a message or a photo.")
    end

    it "requires replies to stay inside the same conversation" do
      reply_target = create(:message)
      message = build(:message, conversation: create(:conversation), reply_to_message: reply_target)

      expect(message).not_to be_valid
      expect(message.errors[:reply_to_message]).to include("must belong to the same conversation.")
    end
  end
end
