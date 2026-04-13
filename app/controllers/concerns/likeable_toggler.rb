module LikeableToggler
  extend ActiveSupport::Concern

  private

  def toggle_like(likeable)
    like = likeable.likes.find_or_initialize_by(user: current_user)
    if like.persisted?
      like.destroy
    else
      like.save
    end
    likeable
  end
end
