require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:connected_user) { create(:user) }

  before do
    sign_in user
    create(:follow, requester: user, receiver: connected_user, status: :accepted)
  end

  describe "GET /users" do
    it "shows chat actions on the people page for connected users" do
      get users_path

      expect(response.body).to include(connected_user.username)
      expect(response.body).to include("Message")
    end
  end
end
