require "rails_helper"

RSpec.describe "Creating a post", type: :system do
  let(:user) { create(:user) }

  before { sign_in user }

  it "lets the user post from the home page" do
    visit root_path

    fill_in "What's happening?", with: "My first post on Lubook"
    click_button "Post"

    expect(page).to have_content("My first post on Lubook")
    expect(user.posts.count).to eq(1)
  end
end
