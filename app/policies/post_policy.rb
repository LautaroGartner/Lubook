class PostPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def update?
    user && record.user_id == user.id
  end

  def destroy?
    user && record.user_id == user.id
  end
end
