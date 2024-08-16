class Api::V1::MessagesController < Api::V1::ApiBaseController
    def create
      @message = Message.new(message_params)
      @message.user_id = current_user.id
      if @message.save
        render json: Api::V1::MessageSerializer.new(@message)
      else
        render json: { error: @message.errors.messages }, status: 422
      end
    end

    private

    def message_params
      params.require(:message).permit(:content, :user_id, :conversation_id, :recipient_id, :message_type, :status)
    end
end
