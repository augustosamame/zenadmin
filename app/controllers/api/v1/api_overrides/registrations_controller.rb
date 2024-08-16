class Api::V1::ApiOverrides::RegistrationsController < Devise::RegistrationsController

  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  prepend_before_action :require_no_authentication, only: [:create]
  #before_action :rewrite_param_names, only: [:create]
  skip_before_action :verify_authenticity_token

  respond_to :json

  skip_authorization_check

  #before_action :validate_partner_data, only: [:create]

  #this will add behaviour to the registrations controller create method
  def create_bak
    if params[:user][:otp]
      @otp_matches = !UserOtp.where(phone: params[:user][:phone], otp: params[:user][:otp]).try(:last).nil?
    else
      @otp_matches = true
    end
    if @otp_matches
      puts 'sign_up_params: '
      puts sign_up_params
      Rails.logger.info 'sign_up_params: '
      Rails.logger.info sign_up_params
      build_resource(sign_up_params)
      resource.save
      unless resource.errors.empty?
        puts 'errors when saving user: '
        puts resource.errors.inspect
        Rails.logger.info 'errors when saving user: '
        Rails.logger.info resource.errors.inspect
      end
      render_resource(resource)
    else
      render json: {error: 'El código de verificación es inválido o ya expiró'}.to_json, status: :not_found
    end
  end

  def create

    @otp_matches = true
    if params[:user][:gender] == 'female' || (params[:user][:gender] == 'male' && params[:user][:betaCode] == 'JUNIO2024')
      if @otp_matches
        puts 'sign_up_params: '
        puts sign_up_params
        Rails.logger.info 'sign_up_params: '
        Rails.logger.info sign_up_params
        build_resource(sign_up_params)
        resource.save
        unless resource.errors.empty?
          puts 'errors when saving user: '
          puts resource.errors.inspect
          Rails.logger.info 'errors when saving user: '
          Rails.logger.info resource.errors.inspect
        end
        render_resource(resource)
      else
        render json: {error: 'El código de verificación es inválido o ya expiró'}.to_json, status: :not_found
      end
    else
      render json: {error: 'El código de acceso beta es inválido o ya expiró'}.to_json, status: :not_found
    end
  end

  def render_resource(resource)
    if resource.errors.empty?
      token = AuthToken.issue_token({ user_id: resource.id })
      resource.token = token
      response.set_header('Authorization', "Bearer #{token}")
      Rails.logger.info "token generated: #{token}"
      puts "token generated:  #{token}"
      UserActivity.create(user_id: resource.id, activity_type: 'signup')
      render json: Api::V1::UserSerializer.new(resource).serialized_json
    else
      validation_error(resource)
    end
  end

  def validation_error(resource)
    render json: {
      data: [
        {
          status: '400',
          title: 'Bad Request',
          error: resource.errors,
          code: '100'
        }
      ]
    }, status: :bad_request
  end

  private

  def sign_up_params
    params.require(:user).permit( :username, :display_username, :age, :gender, :firebase_id, :email, :name, :last_name, :phone, :referrer_id, :locale, :country_code, :country_id , :password, :password_confirmation, :image, :birthday, :interested_in)
  end

  def rewrite_param_names
    request.params[:registration][:user] = {username: request.params[:username], display_username: request.params[:username], email: request.params[:email], password: request.params[:password]}
  end

end
