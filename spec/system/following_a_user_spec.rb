require "rails_helper"

RSpec.describe "Following a user", type: :system do
  let(:requester) { create(:user) }
  let(:receiver) { create(:user) }

  before { sign_in requester }

  it "sends a follow request from the users index" do
    receiver  # ensure the receiver exists
    visit users_path(q: receiver.username)

    expect(page).to have_content(receiver.username)
    click_button "Follow"

    expect(Follow.where(requester: requester, receiver: receiver, status: "pending")).to exist
  end

  it "the receiver can accept a pending request" do
    follow = create(:follow, requester: requester, receiver: receiver)
    follow.accepted!
    expect(follow.reload).to be_accepted
    expect(receiver.followers).to include(requester)
  end
end
