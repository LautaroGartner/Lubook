class Api::V1::Posts::LikesController < Api::V1::BaseController
  include Api::V1::Serialization

  def create
    post = Post.includes(:likes, :comments, user: { profile: { avatar_attachment: :blob } }, images_attachments: :blob).find(params[:post_id])
    post.likes.find_or_create_by!(user: current_api_user)

    render json: { post: serialize_post(post.reload, viewer: current_api_user) }, status: :created
  end

  def destroy
    post = Post.includes(:likes, :comments, user: { profile: { avatar_attachment: :blob } }, images_attachments: :blob).find(params[:post_id])
    post.likes.where(user: current_api_user).destroy_all

    render json: { post: serialize_post(post.reload, viewer: current_api_user) }
  end
end
