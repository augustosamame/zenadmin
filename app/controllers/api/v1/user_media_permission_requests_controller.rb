class Api::V1::UserMediaPermissionRequestsController < Api::V1::ApiBaseController
  before_action :set_user_medium, only: [:create, :update]

  def create
    @permission_request = UserMediaPermissionRequest.new(user: current_user, user_medium: @user_medium)

    if @permission_request.save
      render json: { success: 'Permission request submitted' }, status: :created
    else
      render json: { errors: @permission_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @permission_request = UserMediaPermissionRequest.find(params[:id])
    if @permission_request.update(status: params[:status])
      if @permission_request.approved?
        UserMediaAllowedUser.create!(user: @permission_request.user, user_medium: @permission_request.user_medium)
      elsif @permission_request.denied?
        UserMediaAllowedUser.where(user: @permission_request.user, user_medium: @permission_request.user_medium).destroy_all
      end
      render json: { success: 'Permission request updated' }, status: :ok
    else
      render json: { errors: @permission_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user_medium
    @user_medium = UserMedium.find(params[:user_medium_id])
  end
end
