class Api::V1::UserSettingsController < Api::V1::ApiBaseController
  def index
    @user_settings = UserSetting.where(user_id: current_user.id, internal: false).order(id: :desc)
    authorize! :read, UserSetting
    render json: Api::V1::UserSettingsSerializer.new(@user_settings)
  end

  def update
    @user_setting = UserSetting.find_by(id: params[:id], user_id: current_user.id)
    authorize! :update, @user_setting
    if @user_setting.update(user_setting_params)
      @user_settings = UserSetting.where(user_id: current_user.id, internal: false)
      render json: Api::V1::UserSettingsSerializer.new(@user_settings)
    else
      render json: { errors: @user_setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_setting_params
    params.require(:user_setting).permit(:string_value, :integer_value, :float_value, :datetime_value, :boolean_value)
  end
end
