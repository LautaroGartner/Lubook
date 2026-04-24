class ConversationsController < ApplicationController
  before_action :set_conversation, only: [ :show, :read, :presence, :live ]

  def index
    @conversations = current_user.conversations
                                 .includes(:participants, messages: :user)
                                 .recent
    load_chat_finder
  end

  def create
    other_user = User.find(params[:user_id])

    unless current_user.connected_with?(other_user)
      redirect_to user_path(other_user), alert: "You can only message people you're connected with."
      return
    end

    conversation = Conversation.direct_between!(current_user, other_user)
    redirect_to chat_path(other_user.username)
  end

  def show
    mark_conversation_as_read!
    @messages = @conversation.messages.includes(:user).order(:created_at)
    @message = @conversation.messages.build
    @other_participant = @conversation.other_participant_for(current_user)
  end

  def read
    mark_conversation_as_read!
    render turbo_stream: [
      turbo_stream.replace(
        "chat_badge",
        partial: "shared/chat_badge",
        locals: { count: current_user.unread_chats_count }
      ),
      turbo_stream.replace(
        "mobile_chat_badge",
        partial: "shared/chat_badge",
        locals: {
          count: current_user.unread_chats_count,
          badge_id: "mobile_chat_badge",
          badge_classes: "min-w-5 h-5 items-center justify-center rounded-full bg-stone-900 px-1.5 text-[11px] font-semibold text-white"
        }
      ),
      turbo_stream.replace(
        "mobile_menu_badge",
        partial: "shared/menu_badge",
        locals: {
          notifications_count: current_user.unread_notifications_count,
          chats_count: current_user.unread_chats_count
        }
      )
    ]
  end

  def live
    @messages = @conversation.messages.includes(:user, :reply_to_message).order(:created_at)
    @other_participant = @conversation.other_participant_for(current_user)

    render turbo_stream: turbo_stream.replace(
      "conversation_messages",
      partial: "conversations/messages",
      locals: {
        conversation: @conversation,
        messages: @messages,
        current_user: current_user,
        other_participant: @other_participant
      }
    )
  end

  def presence
    @other_participant = @conversation.other_participant_for(current_user)

    render turbo_stream: turbo_stream.replace(
      "conversation_presence",
      partial: "conversations/presence",
      locals: { other_participant: @other_participant, conversation: @conversation }
    )
  end

  private

  def set_conversation
    @conversations = current_user.conversations.includes(:participants).recent
    @conversation =
      if params[:username].present?
        other_user = current_user.connected_users.find_by!("lower(username) = ?", params[:username].to_s.downcase)
        Conversation.direct_between!(current_user, other_user)
      else
        @conversations.find(params[:id])
      end
  end

  def load_chat_finder
    @chat_query = params[:q].to_s.strip
    @chat_candidates = current_user.connected_users.includes(:profile).order(:username)
    if @chat_query.present?
      @chat_candidates = @chat_candidates.where("username ILIKE ?", "%#{@chat_query}%")
    end
  end

  def mark_conversation_as_read!
    @conversation.conversation_participants
                 .where(user: current_user)
                 .update_all(last_read_at: Time.current, updated_at: Time.current)

    safe_broadcast_replace_to(
      [ current_user, :chats ],
      target: "chat_badge",
      partial: "shared/chat_badge",
      locals: { count: current_user.unread_chats_count }
    )

    safe_broadcast_replace_to(
      [ current_user, :chats ],
      target: "mobile_chat_badge",
      partial: "shared/chat_badge",
      locals: {
        count: current_user.unread_chats_count,
        badge_id: "mobile_chat_badge",
        badge_classes: "min-w-5 h-5 items-center justify-center rounded-full bg-stone-900 px-1.5 text-[11px] font-semibold text-white"
      }
    )

    safe_broadcast_replace_to(
      [ current_user, :chats ],
      target: "mobile_menu_badge",
      partial: "shared/menu_badge",
      locals: {
        notifications_count: current_user.unread_notifications_count,
        chats_count: current_user.unread_chats_count
      }
    )

    @conversation.participants.where.not(id: current_user.id).each do |viewer|
      safe_broadcast_replace_to(
        [ @conversation, viewer ],
        target: "conversation_messages",
        partial: "conversations/messages",
        locals: {
          conversation: @conversation,
          current_user: viewer,
          other_participant: @conversation.other_participant_for(viewer),
          messages: @conversation.messages.includes(:user, :reply_to_message).order(:created_at)
        }
      )
    end
  end

  def safe_broadcast_replace_to(*streamables, **options)
    Turbo::StreamsChannel.broadcast_replace_to(*streamables, **options)
  rescue ArgumentError => error
    Rails.logger.warn("[Turbo broadcast skipped] #{error.class}: #{error.message}")
  end
end
