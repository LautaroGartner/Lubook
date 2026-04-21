class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "conversation_messages",
              partial: "messages/message",
              locals: { message: @message, current_user_id: current_user.id }
            ),
            turbo_stream.replace(
              "message_form",
              partial: "messages/form",
              locals: { conversation: @conversation, message: @conversation.messages.build(reply_to_message: nil) }
            )
          ]
        end
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      @messages = @conversation.messages.includes(:user).order(:created_at)
      @other_participant = @conversation.other_participant_for(current_user)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/form",
            locals: { conversation: @conversation, message: @message }
          ), status: :unprocessable_content
        end
        format.html do
          flash.now[:alert] = @message.errors.full_messages.to_sentence
          render "conversations/show", status: :unprocessable_content
        end
      end
    end
  end

  private

  def set_conversation
    @conversations = current_user.conversations.includes(:participants).recent
    @conversation = @conversations.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:body, :image, :reply_to_message_id)
  end
end
