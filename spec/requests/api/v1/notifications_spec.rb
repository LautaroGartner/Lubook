require "rails_helper"

RSpec.describe "Api::V1::Notifications", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:actor) { create(:user, confirmed_at: Time.current) }
  let!(:api_token) { create(:api_token, user: user) }
  let(:headers) { { "Authorization" => "Bearer #{api_token.raw_token}" } }

  it "lists notifications" do
    create(:notification, recipient: user, actor: actor)

    get "/api/v1/notifications", headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("notifications").size).to eq(1)
  end

  it "clears a notification" do
    notification = create(:notification, recipient: user, actor: actor)

    expect {
      delete "/api/v1/notifications/#{notification.id}", headers: headers
    }.to change(Notification, :count).by(-1)
  end
end
