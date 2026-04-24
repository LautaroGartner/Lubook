class PostImagesController < ApplicationController
  before_action :authenticate_user!

  def destroy
    post = current_user.posts.find(params[:post_id])
    image = post.images.find(params[:id])
    image.purge_later
    redirect_to edit_post_path(post), notice: "Image removed"
  end
end
