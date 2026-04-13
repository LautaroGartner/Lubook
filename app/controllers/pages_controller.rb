class PagesController < ApplicationController
  def home
    user_ids = [ current_user.id ] + current_user.following.pluck(:id)
    @pagy, @posts = pagy(
      Post.where(user_id: user_ids)
          .includes(:user, :likes, :comments, user: { profile: { avatar_attachment: :blob } }, image_attachment: :blob)
          .recent
    )
  end
end
