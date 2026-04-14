class Comments::LikesController < ApplicationController
  include LikeableToggler

  def create
    @comment = Comment.find(params[:comment_id])
    toggle_like(@comment)
    respond_with_like
  end

  def destroy
    @comment = Comment.find(params[:comment_id])
    toggle_like(@comment)
    respond_with_like
  end

  private

  def respond_with_like
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@comment),
          partial: "comments/comment",
          locals: { comment: @comment }
        )
      end
      format.html { redirect_back(fallback_location: post_path(@comment.post)) }
    end
  end
end
