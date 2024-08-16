class Api::V1::UserMediaAllowedUsersController < Api::V1::ApiBaseController
  def create
    user = User.find(params[:user_id])
    user_medium = UserMedium.find(params[:user_medium_id])

    permission = UserMediaAllowedUser.new(user: user, user_medium: user_medium)

    if permission.save
      render json: { success: "Permission granted" }, status: :created
    else
      render json: { errors: permission.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    permission = UserMediaAllowedUser.find_by(user_id: params[:user_id], user_medium_id: params[:user_medium_id])

    if permission&.destroy
      render json: { success: "Permission revoked" }, status: :ok
    else
      render json: { errors: "Permission not found or could not be revoked" }, status: :unprocessable_entity
    end
  end
end
