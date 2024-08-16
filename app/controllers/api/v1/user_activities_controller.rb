class Api::V1::UserActivitiesController < Api::V1::ApiBaseController
  def create
    @user_activity = UserActivity.new(user_activity_params)

    if current_user.test_user
      render json: { message: "Activity discarded for test user" }
    else
      @user_activity.user_id = current_user.id

      if @user_activity.save
        render json: { message: "Activity created" }
      else
        render json: { error: @user_activity.errors.messages }, status: 422
      end
    end
  end

  private

  def user_activity_params
    params.require(:user_activity).permit(:activity_type, activity_data: {})
  end
end
