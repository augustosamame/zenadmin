class Admin::SettingsController < Admin::AdminController
  before_action :set_setting, only: [ :edit, :update ]

  def index
    authorize! :read, Setting
    @setting = Setting.find_by(name: :max_price_discount_percentage)
    redirect_to edit_admin_setting_path(@setting) if @setting
  end

  def edit
    authorize! :update, @setting
  end

  def update
    authorize! :update, @setting

    if @setting.update(setting_params)
      redirect_to admin_settings_path, notice: "Configuración actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_setting
    @setting = Setting.find(params[:id])
  end

  def setting_params
    # Permit the appropriate fields based on the setting's data type
    permitted_params = [ :status ]

    case @setting.data_type
    when "type_string"
      permitted_params << :string_value
    when "type_integer"
      permitted_params << :integer_value
    when "type_float"
      permitted_params << :float_value
    when "type_datetime"
      permitted_params << :datetime_value
    when "type_boolean"
      permitted_params << :boolean_value
    when "type_hash"
      permitted_params << :hash_value
    end

    params.require(:setting).permit(permitted_params)
  end
end
