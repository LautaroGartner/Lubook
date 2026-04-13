class Comments::LikesController < ApplicationController
  include LikeableToggler

  def create
    @comment = Comment.find(params[:comment_id])
    toggle_like(@comment)
    redirect_back(fallback_location: post_path(@comment.post))
  end

  def destroy
    @comment = Comment.find(params[:comment_id])
    toggle_like(@comment)
    redirect_back(fallback_location: post_path(@comment.post))
  end
end
