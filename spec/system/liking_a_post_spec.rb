require "rails_helper"

RSpec.describe "Liking a post", type: :system do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  before { sign_in user }

  it "lets the user like and unlike their own post" do
    visit post_path(post_record)

    expect(page).to have_content("♡")
    click_button "♡ 0"  # the empty-heart button

    expect(page).to have_content("♥ 1")
    expect(post_record.reload.likes.count).to eq(1)

    click_button "♥ 1"
    expect(page).to have_content("♡ 0")
  end
end
