module ApplicationHelper
  include Pagy::NumericHelpers

  MENTION_REGEX = /(^|[^A-Za-z0-9_])@([A-Za-z0-9_.]{3,30})/.freeze

  def comment_body_html(text)
    usernames = text.to_s.scan(MENTION_REGEX).map { |(_, username)| username.downcase }.uniq
    mentioned_users = User.where("lower(username) IN (?)", usernames).index_by { |user| user.username.downcase }

    paragraphs = text.to_s.split(/\n+/).map do |line|
      escaped = ERB::Util.html_escape(line)
      formatted = escaped.gsub(MENTION_REGEX) do
        prefix = Regexp.last_match(1)
        username = Regexp.last_match(2)
        mentioned_user = mentioned_users[username.downcase]

        if mentioned_user
          %(#{prefix}<a href="#{user_path(mentioned_user)}" class="font-medium text-sky-700 hover:text-sky-800 hover:underline">@#{username}</a>)
        else
          Regexp.last_match(0)
        end
      end

      content_tag(:p, formatted.html_safe)
    end

    safe_join(paragraphs.presence || [ content_tag(:p, "") ])
  end

  def chat_presence_text(user)
    return unless user&.share_last_seen?
    return "Active now" if user.active_now?
    return unless user.last_active_at.present?

    "Last active #{time_ago_in_words(user.last_active_at)} ago"
  end

  def chat_read_receipt_text(conversation, current_user, other_participant)
    return unless chat_read_receipt_message_id(conversation, current_user, other_participant)

    other_state = conversation.participant_for(other_participant)
    return unless other_state&.last_read_at.present?

    "Seen #{time_ago_in_words(other_state.last_read_at)} ago"
  end

  def chat_read_receipt_message_id(conversation, current_user, other_participant)
    return unless other_participant&.share_read_receipts?

    other_state = conversation.participant_for(other_participant)
    return unless other_state&.last_read_at.present?

    conversation.messages
                .where(user: current_user)
                .where("created_at <= ?", other_state.last_read_at)
                .order(created_at: :desc)
                .pick(:id)
  end
end
