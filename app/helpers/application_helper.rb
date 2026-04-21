module ApplicationHelper
  include Pagy::Frontend

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
end
