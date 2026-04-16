require "rails_helper"

RSpec.describe "Signup", type: :system do
  it "creates a new user record when the form is submitted" do
    visit new_user_registration_path

    fill_in "Username", with: "newuser"
    fill_in "Email", with: "new@example.com"
    fill_in "Password", with: "testpassword123", match: :prefer_exact
    fill_in "Confirm password", with: "testpassword123"

    click_button "Sign up"

    expect(User.find_by(email: "new@example.com")).to be_present
  end
end
