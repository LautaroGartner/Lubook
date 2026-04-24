require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  describe "POST /api/v1/auth/sign_in" do
    let(:user) { create(:user, confirmed_at: Time.current) }

    it "returns a bearer token for valid credentials" do
      post "/api/v1/auth/sign_in", params: {
        email: user.email,
        password: user.password,
        device_name: "Lubo iPhone"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      expect(json["token"]).to be_present
      expect(json["token_type"]).to eq("Bearer")
      expect(json.dig("user", "username")).to eq(user.username)
      expect(ApiToken.count).to eq(1)
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/sign_in", params: {
        email: user.email,
        password: "wrong-password"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
