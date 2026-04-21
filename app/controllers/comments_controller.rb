class CommentsController < ApplicationController
  before_action :set_comment, only: [ :destroy ]

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(normalized_comment_params.merge(user: current_user))
    authorize @comment

    if @comment.save
      respond_to do |format|
        format.turbo_stream do
          load_post_comments
          render turbo_stream: turbo_stream.replace(
            "post_comments_section",
            partial: "comments/section",
            locals: { post: @post, comments: @comments, comment: Comment.new, expanded_thread_ids: expanded_thread_ids }
          )
        end
        format.html do
          redirect_to post_path(@post, anchor: helpers.dom_id(@comment)),
                      notice: @comment.parent_id? ? "Reply added." : "Comment added."
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          load_post_comments
          render turbo_stream: turbo_stream.replace(
            "post_comments_section",
            partial: "comments/section",
            locals: { post: @post, comments: @comments, comment: @comment, expanded_thread_ids: expanded_thread_ids }
          ), status: :unprocessable_content
        end
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    authorize @comment
    @post = @comment.post
    @comment.destroy
    respond_to do |format|
      format.turbo_stream do
        load_post_comments
        render turbo_stream: turbo_stream.replace(
          "post_comments_section",
          partial: "comments/section",
          locals: { post: @post, comments: @comments, comment: Comment.new, expanded_thread_ids: expanded_thread_ids }
        )
      end
      format.html { redirect_to post_path(@post), notice: "Comment deleted." }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_id, :reply_target_user_id)
  end

  def load_post_comments
    @comments = @post.comments.chronological.includes(:likes, :parent, user: { profile: { avatar_attachment: :blob } })
  end

  def expanded_thread_ids
    Array(params[:expanded_thread_ids]).filter_map do |value|
      Integer(value, exception: false)
    end.uniq
  end

  def normalized_comment_params
    permitted = comment_params.to_h.symbolize_keys
    return permitted unless permitted[:parent_id].present?

    parent_comment = @post.comments.find_by(id: permitted[:parent_id])
    return permitted unless parent_comment

    permitted[:parent_id] = parent_comment.thread_root_id

    permitted
  end
end
