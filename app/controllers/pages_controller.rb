class PagesController < ApplicationController
  def home
    following_ids = current_user.following.pluck(:id)
    feed_user_ids = following_ids + [ current_user.id ]

    @pagy, @posts = pagy(
      Post.where(user_id: feed_user_ids)
          .includes(:likes, :comments, user: { profile: { avatar_attachment: :blob } }, image_attachment: :blob)
          .order(created_at: :desc)
    )
  end
end
