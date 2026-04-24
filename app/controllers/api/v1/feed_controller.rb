class Api::V1::FeedController < Api::V1::BaseController
  include Api::V1::Serialization

  def index
    following_ids = current_api_user.following.pluck(:id)
    feed_user_ids = following_ids + [ current_api_user.id ]

    posts = Post.where(user_id: feed_user_ids)
                .includes(:likes, :comments, user: { profile: { avatar_attachment: :blob } }, image_attachment: :blob)
                .order(created_at: :desc)

    render json: {
      posts: posts.map { |post| serialize_post(post, viewer: current_api_user) }
    }
  end
end
