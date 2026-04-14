require "rails_helper"

RSpec.describe ProfilePolicy do
  subject { described_class.new(user, profile) }

  let(:owner) { create(:user) }
  let(:profile) { owner.profile }

  context "when the user owns the profile" do
    let(:user) { owner }
    it { is_expected.to permit_actions(%i[edit update]) }
  end

  context "when the user is someone else" do
    let(:user) { create(:user) }
    it { is_expected.to forbid_actions(%i[edit update]) }
  end
end
