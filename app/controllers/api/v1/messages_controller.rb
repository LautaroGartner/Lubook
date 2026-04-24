class Api::V1::MessagesController < Api::V1::BaseController
  include Api::V1::Serialization

  def create
    conversation = current_api_user.conversations.find(params[:conversation_id])
    message = conversation.messages.build(message_params.merge(user: current_api_user))

    if message.save
      render json: { message: serialize_message(message, viewer: current_api_user) }, status: :created
    else
      render json: { error: message.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end

  private

  def message_params
    params.require(:message).permit(:body, :reply_to_message_id)
  end
end
