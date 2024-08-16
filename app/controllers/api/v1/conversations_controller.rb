class Api::V1::ConversationsController < Api::V1::ApiBaseController
    def index
      @conversations = Conversation.includes([ :recipient ]).where("sender_id = ? OR recipient_id = ?", current_user.id, current_user.id).order(last_message_at: :desc)
      render json: Api::V1::ConversationSerializer.new(@conversations, { params: { viewer: current_user } })
    end

    def show
      @conversation = Conversation.includes(:sender, :recipient).find(params[:id])
      unless current_user.id == @conversation.sender_id || current_user.id == @conversation.recipient_id
        render json: { error: "Unauthorized" }, status: 401
        return
      end
      render json: Api::V1::ConversationSerializer.new(@conversation, { params: { viewer: current_user, include_messages: true } })
    end

    def accept_invitation
      @conversation = Conversation.find(params[:id])
      if @conversation.update(invite_status: "accepted")
        Notification.create(
          user_id: @conversation.sender_id,
          sender_id: @conversation.recipient_id,
          notification_type: "invitation_result",
          title: "#{@conversation.recipient.display_username} ha aceptado tu invitación!",
          body: "Prepárate para engreir! Ya puedes enviarle mensajes a #{@conversation.recipient.display_username}",
          url: "/chat/#{@conversation.id}",
          notif_object_type: "Conversation",
          notif_object_id: @conversation.id
        )
        UserActivity.create(user_id: @conversation.recipient_id, activity_type: "accepted_invite", activity_data: { 'invite_from': @conversation.sender.display_username })
        render json: { message: "Invitation accepted" }, status: :ok
      else
        render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def reject_invitation
      @conversation = Conversation.find(params[:id])
      if @conversation.update(invite_status: "rejected")
        Notification.create(
          user_id: @conversation.sender_id,
          sender_id: @conversation.recipient_id,
          notification_type: "invitation_result",
          title: "#{@conversation.recipient.display_username} ha rechazado tu invitación!",
          body: "#{@conversation.recipient.display_username} no aceptó tu invitación. Pero no te preocupes! Hay otros peces en el mar. Sigue invitando y prepárate para engreir!",
          url: "/chat/#{@conversation.id}",
          notif_object_type: "Conversation",
          notif_object_id: @conversation.id
        )
        UserActivity.create(user_id: @conversation.recipient_id, activity_type: "rejected_invite", activity_data: { 'invite_from': @conversation.sender.display_username })
        render json: { message: "Invitation rejected" }, status: :ok
      else
        render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end
end
