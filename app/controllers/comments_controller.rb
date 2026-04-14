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

  def create
  @post = Post.find(params[:post_id])
  @comment = @post.comments.build(comment_params.merge(user: current_user))
  authorize @comment

  if @comment.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("comments", partial: "comments/comment", locals: { comment: @comment }),
          turbo_stream.replace("comment_form", partial: "comments/form", locals: { post: @post, comment: Comment.new })
        ]
      end
      format.html { redirect_to post_path(@post), notice: "Comment added." }
    end
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
