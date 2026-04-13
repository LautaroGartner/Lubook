class ProfilePolicy < ApplicationPolicy
  def edit?
    record.user_id == user.id
  end

  def update?
    edit?
  end
end
