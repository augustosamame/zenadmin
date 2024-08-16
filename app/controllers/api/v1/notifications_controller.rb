class Api::V1::NotificationsController < Api::V1::ApiBaseController
  before_action :set_notification, only: [:mark_as_read, :archive]
  
  # GET /notifications
  def index
    @notifications = Notification.includes([:sender]).where(user_id: current_user.id).order(created_at: :desc)
    render json: Api::V1::NotificationSerializer.new(@notifications)
      
  end

  # POST /notifications/:id/mark_as_read
  def mark_as_read
    if @notification.update(status: 'read')
      #ActionCable.server.broadcast("user_#{@notification.user_id}", { user: Api::V1::UserSerializer.new(@notification.user) })
      render json: { success: true }, status: :ok
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def archive
    if @notification.update(status: 'archived')
      #ActionCable.server.broadcast("user_#{@notification.user_id}", { user: Api::V1::UserSerializer.new(@notification.user) })
      render json: { success: true }, status: :ok
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  end

end