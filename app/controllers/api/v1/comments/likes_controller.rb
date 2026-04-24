class Api::V1::Comments::LikesController < Api::V1::BaseController
  include Api::V1::Serialization

  def create
    comment = Comment.includes(:likes, user: { profile: { avatar_attachment: :blob } }).find(params[:comment_id])
    comment.likes.find_or_create_by!(user: current_api_user)

    render json: { comment: serialize_comment(comment.reload, viewer: current_api_user) }, status: :created
  end

  def destroy
    comment = Comment.includes(:likes, user: { profile: { avatar_attachment: :blob } }).find(params[:comment_id])
    comment.likes.where(user: current_api_user).destroy_all

    render json: { comment: serialize_comment(comment.reload, viewer: current_api_user) }
  end
end
