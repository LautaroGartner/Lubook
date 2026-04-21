class ConversationsController < ApplicationController
  before_action :set_conversation, only: [ :show, :read ]

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
    redirect_to conversation_path(conversation)
  end

  def show
    mark_conversation_as_read!
    @messages = @conversation.messages.includes(:user).order(:created_at)
    @message = @conversation.messages.build
    @other_participant = @conversation.other_participant_for(current_user)
  end

  def read
    mark_conversation_as_read!
    head :ok
  end

  private

  def set_conversation
    @conversations = current_user.conversations.includes(:participants).recent
    @conversation = @conversations.find(params[:id])
  end

  def load_chat_finder
    @chat_query = params[:q].to_s.strip
    @chat_candidates = current_user.connected_users.includes(:profile).order(:username)
    if @chat_query.present?
      @chat_candidates = @chat_candidates.where("username ILIKE ?", "%#{@chat_query}%")
    end
  end

  def mark_conversation_as_read!
    participant = @conversation.conversation_participants.find_by!(user: current_user)
    participant.update(last_read_at: Time.current)

    Turbo::StreamsChannel.broadcast_replace_to(
      [ current_user, :chats ],
      target: "chat_badge",
      partial: "shared/chat_badge",
      locals: { count: current_user.unread_chats_count }
    )

    @conversation.participants.where.not(id: current_user.id).find_each do |viewer|
      Turbo::StreamsChannel.broadcast_replace_to(
        [ @conversation, viewer ],
        target: "chat_read_state",
        partial: "conversations/read_state",
        locals: {
          conversation: @conversation,
          current_user: viewer,
          other_participant: @conversation.other_participant_for(viewer)
        }
      )
    end
  end
end
