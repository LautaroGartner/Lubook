require "rails_helper"

RSpec.describe "filter parameter logging" do
  it "filters chat and content bodies from logs" do
    filter_string = Rails.application.config.filter_parameters.join(" ")

    expect(filter_string).to include("body")
    expect(filter_string).to include("message")
    expect(filter_string).to include("comment")
    expect(filter_string).to include("post")
  end
end
