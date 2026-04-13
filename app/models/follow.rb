class Follow < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :receiver,  class_name: "User"

  enum :status, { pending: 0, accepted: 1 }, default: :pending

  validates :requester_id, uniqueness: { scope: :receiver_id }
  validate  :not_self_follow

  private

  def not_self_follow
    errors.add(:receiver, "can't be yourself") if requester_id == receiver_id
  end
end
