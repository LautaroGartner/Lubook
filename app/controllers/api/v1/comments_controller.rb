class Api::V1::CommentsController < Api::V1::BaseController
  include Api::V1::Serialization

  def create
    post = Post.find(params[:post_id])
    comment = post.comments.build(normalized_comment_params.merge(user: current_api_user))
    return unless authorize_comment!(comment)

    if comment.save
      render json: { comment: serialize_comment(comment, viewer: current_api_user) }, status: :created
    else
      render json: { error: comment.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id, :reply_target_user_id)
  end

  def normalized_comment_params
    permitted = comment_params.to_h.symbolize_keys
    return permitted unless permitted[:parent_id].present?

    parent_comment = Post.find(params[:post_id]).comments.find_by(id: permitted[:parent_id])
    return permitted unless parent_comment

    permitted[:parent_id] = parent_comment.thread_root_id
    permitted
  end

  def authorize_comment!(comment)
    policy = CommentPolicy.new(current_api_user, comment)
    return true if policy.create?

    render json: { error: "You're not authorized to do that." }, status: :forbidden
    false
  end
end
