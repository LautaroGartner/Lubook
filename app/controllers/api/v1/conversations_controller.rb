class Api::V1::ConversationsController < Api::V1::BaseController
  include Api::V1::Serialization

  def index
    conversations = current_api_user.conversations
                                    .includes(:participants, messages: :user)
                                    .recent

    render json: {
      conversations: conversations.map { |conversation| serialize_conversation(conversation, viewer: current_api_user) }
    }
  end

  def create
    other_user = User.find(params[:user_id])

    unless current_api_user.connected_with?(other_user)
      render json: { error: "You can only message people you're connected with." }, status: :forbidden
      return
    end

    conversation = Conversation.direct_between!(current_api_user, other_user)

    render json: {
      conversation: serialize_conversation(conversation, viewer: current_api_user)
    }, status: :created
  end

  def show
    conversation = current_api_user.conversations
                                   .includes(participants: { profile: { avatar_attachment: :blob } }, messages: { user: { profile: { avatar_attachment: :blob } } })
                                   .find(params[:id])

    mark_as_read!(conversation)

    render json: {
      conversation: serialize_conversation(conversation, viewer: current_api_user),
      messages: conversation.messages.order(:created_at).map { |message| serialize_message(message, viewer: current_api_user) }
    }
  end

  def read
    conversation = current_api_user.conversations.find(params[:id])
    mark_as_read!(conversation)
    head :ok
  end

  private

  def mark_as_read!(conversation)
    conversation.conversation_participants
                .where(user: current_api_user)
                .update_all(last_read_at: Time.current, updated_at: Time.current)
  end
end
