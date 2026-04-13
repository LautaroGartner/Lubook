class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    record.user_id == user.id || record.post.user_id == user.id
  end
end
