class CommentsController < ApplicationController
  before_action :set_comment, only: [ :destroy ]

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params.merge(user: current_user))
    authorize @comment

    if @comment.save
      redirect_to post_path(@post), notice: "Comment added."
    else
      redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @comment
    post = @comment.post
    @comment.destroy
    redirect_to post_path(post), notice: "Comment deleted."
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
