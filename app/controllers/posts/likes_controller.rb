class Posts::LikesController < ApplicationController
  include LikeableToggler

  def create
    @post = Post.find(params[:post_id])
    toggle_like(@post)
    respond_with_like
  end

  def destroy
    @post = Post.find(params[:post_id])
    toggle_like(@post)
    respond_with_like
  end

  private

  def respond_with_like
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@post, :like),
          partial: "posts/like_button",
          locals: { post: @post }
        )
      end
      format.html { redirect_back(fallback_location: post_path(@post)) }
    end
  end
end
