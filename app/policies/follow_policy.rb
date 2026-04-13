class FollowPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    record.requester_id == user.id || record.receiver_id == user.id
  end

  def accept?
    record.receiver_id == user.id && record.pending?
  end

  def reject?
    accept?
  end
end
