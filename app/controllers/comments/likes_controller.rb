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
        post = @comment.post
        comments = post.comments.chronological.includes(:likes, :parent, user: { profile: { avatar_attachment: :blob } })

        render turbo_stream: turbo_stream.replace(
          "post_comments_section",
          partial: "comments/section",
          locals: {
            post: post,
            comments: comments,
            comment: Comment.new,
            expanded_thread_ids: expanded_thread_ids
          }
        )
      end
      format.html { redirect_back(fallback_location: post_path(@comment.post)) }
    end
  end

  def expanded_thread_ids
    Array(params[:expanded_thread_ids]).filter_map do |value|
      Integer(value, exception: false)
    end.uniq
  end
end
