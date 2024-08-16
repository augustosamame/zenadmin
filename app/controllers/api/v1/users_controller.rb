class Api::V1::UsersController < Api::V1::ApiBaseController

  protect_from_forgery with: :null_session, only: [:suggested_username, :phone_number_exists, :username_exists, :forgot_password, :otp_and_new_password]
  skip_before_action :verify_authenticity_token, only: [:suggested_username, :phone_number_exists, :username_exists, :forgot_password, :otp_and_new_password]
  skip_before_action :authenticate_user_with_token, only: [:suggested_username, :phone_number_exists, :username_exists, :forgot_password, :otp_and_new_password]

  def reset_password
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    if password == password_confirmation
      current_user.password = password
      if current_user.save
        render json: { message: 'La contraseña se cambió correctamente' }
      else
        render json: { error: current_user.errors.full_messages }, status: 422
      end
    else
      render json: { error: 'Passwords do not match' }, status: 422
    end
  end

  def suggested_username
    username_from_pool = UsernamePool.order("RANDOM()").where(status: 'status_free').try(:first)
    if username_from_pool.present?
      suggested_username = username_from_pool.username
      #TODO warn when less than 500 usernames are left
    else
      raise "No more usernames available in pool"
    end
    render json: { suggested_username: suggested_username }
  end

  def forgot_password
    phone_number = params[:phone]
    user = User.find_by(phone: phone_number)
    user51 = User.find_by(phone: "51#{phone_number}")
    if user.present?
      user.send_otp
      render json: { message: 'OTP sent' }
    elsif user51.present?
      user51.send_otp
      render json: { message: 'OTP sent' }
    else
      render json: { error: 'El número móvil no existe' }, status: 200
    end
  end

  def otp_and_new_password
    user = User.find_by(phone: params[:phone])
    if user.blank?
      user = User.find_by(phone: "51#{params[:phone]}")
      if user.blank?
        render json: { message: 'phone does not match' }, status: :unauthorized
        return
      end
    end
    if user.otp == params[:otp] || (ENV["ROLLBAR_ENV"] != 'production' && params[:otp] == '123456')
      user.password = params[:password]
      if user.save
        render json: { message: 'Password updated successfully' }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { message: 'El código de seguridad no coincide' }, status: :unauthorized
    end
  end

  def phone_number_exists
    phone_number = params[:phone]
    user = User.find_by(phone: phone_number)
    user51 = User.find_by(phone: "51#{phone_number}")
    render json: { exists: user.present? || user51.present? }
  end

  def username_exists
    username = params[:username].downcase
    user = User.find_by(username: username)
    render json: { exists: user.present? }
  end

  #def show
  #  @user = User.find(params[:id])
  #  authorize! :read, @user
  #  render json: Api::V1::UserProfileSerializer.new(@user, params: { include_profile_image: true, viewer: current_user })
  #end

  def find_by_current_user
    @user = User.find_by(id: current_user.id)
    authorize! :read, @user
    render json: Api::V1::UserSerializer.new(@user)
  end

  def show_by_username
    @user = User.find_by(username: params[:username].downcase)
    authorize! :show_by_username, User
    render json: Api::V1::UserProfileSerializer.new(@user, params: { viewer: current_user })
  end

  def update_push_token
    @user = User.find(current_user.id)
    authorize! :update, @user

    begin
      if params[:push_token].is_a?(String)
        push_token = params[:push_token]
      else
        push_token = params[:push_token].permit!.to_h
      end

      if push_token.is_a?(Hash) && push_token.key?('endpoint') && push_token.key?('keys')
        # Handle web push subscription
        subscription = push_token.slice('endpoint', 'keys')
        @user.update(web_push_subscription: subscription.to_json)
        render json: { message: 'Web push subscription added' }
      else
        @user.update(fcm_push_token: params[:push_token])
        render json: { message: 'Token added' }
      end
    rescue JSON::ParserError
      render json: { error: 'Invalid push token' }, status: :unprocessable_entity
    end
  end

  def change_username
    @user = User.find(current_user.id)
    authorize! :update, @user
    username = params[:username].downcase
    if User.find_by(username: username).nil?
      @user.update(username: username, display_username: username)
      render json: Api::V1::UserSerializer.new(@user)
    else
      render json: { error: 'Username already exists' }, status: 422
    end
  end

  def update
    @user = User.find(current_user.id)
    authorize! :update, @user

    Rails.logger.info "Received params: #{params.inspect}"
    Rails.logger.info "Permitted: #{user_params.permitted?}"

    # Merge user_profile_attributes
    if params[:user][:user_profile_attributes]
      existing_attributes = @user.user_profile.attributes
      Rails.logger.info "Existing attributes: #{existing_attributes.inspect}"
      new_attributes = params[:user].delete(:user_profile_attributes).permit(:headline, :about_me, :virtual_active, :dates_active, :travel_active, :longterm_active, :match_min_age, :match_max_age, :match_min_level, allowed_countries: [])
      Rails.logger.info "New attributes: #{new_attributes.inspect}"
      merged_attributes = existing_attributes.merge(new_attributes) do |key, old_val, new_val|
        new_val.nil? ? old_val : new_val
      end

      params[:user][:user_profile_attributes] = merged_attributes
    end

    if @user.update(user_params)
      render json: Api::V1::UserSerializer.new(@user)
    else
      render json: { error: @user.errors.messages }, status: 422
    end
  end

  def delete_account
    @user = User.find(current_user.id)
    user_phone = @user.phone
    user_id = @user.id
    authorize! :destroy, @user
    if @user.destroy
      Rails.logger.info "User #{user_id} deleted their account"
      Services::LabsMobileSms.new.send_sms_to_number("Un usuario eliminó su cuenta en Dolce Girls: #{user_phone}.", '51986976377')
      render json: { message: 'Account deleted' }
    else
      render json: { error: @user.errors.messages }, status: 422
    end
  end

  def pre_update_phone
    @user = User.find(current_user.id)
    authorize! :update, @user
    phone_does_not_exist = User.find_by(phone: params[:new_phone]).nil?
    if phone_does_not_exist
      #send otp
      @user.send_otp
      render json: { message: 'OTP sent' }
    else
      render json: { error: 'Phone number already exists' }, status: 422
    end
  end

  def update_phone
    @user = User.find(current_user.id)
    authorize! :update, @user  
    otp_matches = @user.otp == params[:otp]
    if otp_matches
      @user.phone = params[:phone]
      phone_does_not_exist = User.find_by(phone: params[:new_phone]).nil?
      if phone_does_not_exist
        @user.save
        render json: Api::V1::UserSerializer.new(@user)
      else
        render json: { error: 'El teléfono ya existe' }, status: 422
      end
    else
      render json: { error: 'el código de seguridad no coincide' }, status: 422
    end
    
  end

  private

    def user_params
      params.require(:user).permit(:username, :display_username, :phone, :birthday, :location, :latitude, :longitude, :unread_notification_count, user_profile_attributes: [:headline, :about_me, :virtual_active, :dates_active, :travel_active, :longterm_active, :match_min_age, :match_max_age, :match_min_level, { allowed_countries: [] }])
    end

end
