class Follow < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :receiver,  class_name: "User"

  enum :status, { pending: 0, accepted: 1 }, default: :pending
  scope :pending,  -> { where(status: :pending) }
  scope :accepted, -> { where(status: :accepted) }

  validates :requester_id, uniqueness: { scope: :receiver_id }
  validate  :not_self_follow

  after_create_commit :notify_receiver_of_request!
  after_update_commit :notify_requester_of_acceptance!, if: :saved_change_to_status?

  private

  def not_self_follow
    errors.add(:receiver, "can't be yourself") if requester_id == receiver_id
  end

  def notify_receiver_of_request!
    NotificationDispatcher.notify!(
      recipient: receiver,
      actor: requester,
      action: "follow_request",
      notifiable: self
    )
  end

  def notify_requester_of_acceptance!
    return unless accepted?

    NotificationDispatcher.notify!(
      recipient: requester,
      actor: receiver,
      action: "follow_accepted",
      notifiable: self
    )
  end
end
