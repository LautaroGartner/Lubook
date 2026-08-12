require "rails_helper"

RSpec.describe "Password visibility" do
  it "provides an accessible reveal control on the sign-in form" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="password-visibility"')
    expect(response.body).to include('data-action="password-visibility#toggle"')
    expect(response.body).to include('aria-label="Show password"')
  end
end
