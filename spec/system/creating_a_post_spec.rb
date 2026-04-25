require "base64"
require "tempfile"
require "rails_helper"

RSpec.describe "Creating a post", type: :system do
  TINY_PNG_BASE64 = <<~BASE64.delete("\n").freeze
    iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WnW
    hK0AAAAASUVORK5CYII=
  BASE64

  let(:user) { create(:user) }

  before { sign_in user }

  def png_upload
    file = Tempfile.new([ "post-image", ".png" ])
    file.binmode
    file.write(Base64.decode64(TINY_PNG_BASE64))
    file.rewind
    file
  end

  it "lets the user post from the home page" do
    visit root_path

    fill_in "What's happening?", with: "My first post on Lubook"
    click_button "Post"

    expect(page).to have_content("My first post on Lubook")
    expect(user.posts.count).to eq(1)
  end

  it "renders an attached image directly beneath the post body on the feed" do
    image_file = png_upload
    post = user.posts.create!(body: "Flat white with my beautiful girl <3")
    post.images.attach(io: image_file, filename: "post-image.png", content_type: "image/png")

    visit root_path

    within("article", text: post.body) do
      expect(page).to have_css("div.prose-tight")
      expect(page).to have_css("div.prose-tight + div[data-controller='carrousel'] img")
    end
  ensure
    image_file&.close!
  end
end
