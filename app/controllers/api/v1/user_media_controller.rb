class Api::V1::UserMediaController < Api::V1::ApiBaseController

  def index
    @user_media = UserMedium.where(user_id: current_user.id).order(:profile_image => :desc, :id => :asc)
    authorize! :read, UserMedium
    render json: Api::V1::UserMediaSerializer.new(@user_media)
  end

  def show
    @user_media = UserMedium.find_by(id: params[:id], user_id: current_user.id, )
    authorize! :read, @user_media
    render json: Api::V1::UserMediaSerializer.new(@user_media)
  end

  def set_profile_image
    @user_media = UserMedium.find_by(id: params[:id], user_id: current_user.id)
    authorize! :update, @user_media
    @user_media.set_new_profile_image
    render json: Api::V1::UserMediaSerializer.new(@user_media)
  end

  def toggle_media_privacy
    @user_media = UserMedium.find_by(id: params[:id], user_id: current_user.id)
    authorize! :update, @user_media
    @user_media.toggle_media_privacy
    render json: Api::V1::UserMediaSerializer.new(@user_media)
  end

  def request_media_permission
    @user_media = UserMedium.find_by(id: params[:id])
    @user_media.request_media_permission(current_user)
    render json: Api::V1::UserMediaSerializer.new(@user_media)
  end

  def toggle_media_privacy_request
    @media_requests = UserMediaPermissionRequest.where(user_id: current_user.id, requested_by_id: params[:requester_id])
    authorize! :update, @media_requests.first
    @media_requests.each do |media_request|
      media_request.update(status: params[:status])
    end
    if params[:status] == 'approved'
      UserMedium.where(user_id: current_user.id, visibility: 'visibility_private').each do |user_medium|
        UserMediaAllowedUser.create(user_id: params[:requester_id], user_medium_id: user_medium.id)
      end
    else
      UserMediaAllowedUser.where(user_id: params[:requester_id]).destroy_all
    end
    #modify pednding notification so it will show the status of the request
    notification = Notification.find_by(user_id: current_user.id, sender_id: params[:requester_id],notification_type: 'private_photo_request')
    
    if notification.present?
      notification.update(extra_data: {
        user_medium_id: notification.extra_data['user_medium_id'],
        user_id: notification.extra_data['user_id'],
        user_name: notification.extra_data['user_name'],
        status: params[:status]
      })
    end

    #create notification for requester that the request has been approved or denied
    if params[:status] == 'approved'
      Notification.create(user_id: params[:requester_id], sender_id: current_user.id, notification_type: 'private_photo_request_response', title: "Solicitud de permiso para ver fotos en modo privado aprobada", body: "#{current_user.display_username} ha aprobado tu solicitud para ver sus fotos en modo privado.", extra_data: { user_medium_id: notification.extra_data['user_medium_id'], user_id: current_user.id, user_name: current_user.display_username, status: 'approved' })
    else
      Notification.create(user_id: params[:requester_id], sender_id: current_user.id, notification_type: 'private_photo_request_response', title: "Solicitud de permiso para ver fotos en modo privado denegada", body: "#{current_user.display_username} ha denegado tu solicitud para ver sus fotos en modo privado.", extra_data: { user_medium_id: notification.extra_data['user_medium_id'], user_id: current_user.id, user_name: current_user.display_username, status: 'denied' })
    end
    render json: { message: 'Toggle privacy successful' }
  end

  def create
    raise "no current_user" unless current_user
    @user_media = UserMedium.new(user_media_params)
    @user_media.user_id = current_user.id
    authorize! :create, @user_media
    @user_media.s3_object_key = "uploads/user_media/#{current_user.id}/#{user_media_params[:s3_object_key]}"
    if @user_media.save
      UserActivity.create(user_id: current_user.id, activity_type: 'post_photo', activity_data: { user_medium_id: @user_media.s3_object_key })
      render json: Api::V1::UserMediaSerializer.new(@user_media)
    else
      render json: { error: @user_media.errors.messages }, status: 422
    end
  end

  def destroy
    @user_media = UserMedium.find_by(id: params[:id], user_id: current_user.id)
    authorize! :destroy, @user_media
    #TODO create a backup of destroyed media

    if @user_media.destroy
      UserActivity.create(user_id: current_user.id, activity_type: 'delete_photo')
      render json: { message: 'Deleted' }
    else
      render json: { error: @user_media.errors.messages }, status: 422
    end
  end

  private

  def user_media_params
    params.require(:user_media).permit(:media_data, :s3_object_key, :media_type, :filterless, :visibility, :visible_levels, :visible_locations, :status, :requested_by_id)
  end

end
