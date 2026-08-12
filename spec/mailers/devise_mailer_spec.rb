require "rails_helper"

RSpec.describe Devise::Mailer do
  let(:user) { build(:user, email: "reader@example.com") }

  it "brands password reset emails" do
    mail = described_class.reset_password_instructions(user, "reset-token")

    expect(mail.subject).to eq("Reset your Lubook password")
    expect(mail[:from].display_names).to eq([ "Lubook" ])
    expect(mail.body.encoded).to include("Lubook", "Choose a new password")
  end

  it "brands confirmation emails" do
    mail = described_class.confirmation_instructions(user, "confirmation-token")

    expect(mail.subject).to eq("Confirm your Lubook account")
    expect(mail.body.encoded).to include("Welcome to Lubook", "Confirm my account")
  end
end
