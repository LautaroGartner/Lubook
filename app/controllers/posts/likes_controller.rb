class Posts::LikesController < ApplicationController
  include LikeableToggler

  def create
    @post = Post.find(params[:post_id])
    toggle_like(@post)
    redirect_back(fallback_location: post_path(@post))
  end

  def destroy
    @post = Post.find(params[:post_id])
    toggle_like(@post)
    redirect_back(fallback_location: post_path(@post))
  end
end
