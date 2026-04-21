class NotificationDispatcher
  def self.notify!(recipient:, actor:, action:, notifiable:)
    return if recipient.blank? || actor.blank?
    return if recipient == actor

    Notification.create!(
      recipient: recipient,
      actor: actor,
      action: action,
      notifiable: notifiable
    )
  end
end
