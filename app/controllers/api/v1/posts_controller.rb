class Api::V1::PostsController < Api::V1::BaseController
  include Api::V1::Serialization

  def create
    post = current_api_user.posts.build(post_params)
    return unless authorize_post!(post, :create?)

    if post.save
      render json: { post: serialize_post(post.reload, viewer: current_api_user) }, status: :created
    else
      render json: { error: post.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end

  def show
    post = Post.includes(
      :likes,
      { comments: [ :likes, :parent, { user: { profile: { avatar_attachment: :blob } } } ] },
      { user: { profile: { avatar_attachment: :blob } } },
      images_attachments: :blob
    ).find(params[:id])

    comments = post.comments.chronological.includes(:likes, :parent, user: { profile: { avatar_attachment: :blob } })

    render json: {
      post: serialize_post(post, viewer: current_api_user),
      comments: comments.map { |comment| serialize_comment(comment, viewer: current_api_user) }
    }
  end

  private

  def post_params
    params.require(:post).permit(:body)
  end

  def authorize_post!(post, action)
    policy = PostPolicy.new(current_api_user, post)
    return true if policy.public_send(action)

    render json: { error: "You're not authorized to do that." }, status: :forbidden
    false
  end
end
