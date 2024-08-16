module Api::V1
  class ApiBaseController < ActionController::Base
    # protect_from_forgery with: :exception, unless: -> { request.format.json? }
    protect_from_forgery with: :null_session
    before_action :authenticate_user_with_token, unless: [ :devise_controller? ]
    after_action :set_app_version_header

    def authenticate_user_with_token
      # TODO specif response if token is invalid to force app to relogin
      unless request.headers["Authorization"].blank?
        Rails.logger.debug("received Authorization header is #{request.headers["Authorization"]}")
        token = request.headers["Authorization"].gsub("Bearer ", "")
        if AuthToken.valid?(token) && !JwtDenylist.find_by(jti: token)
          payload = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"])
        end
        Rails.logger.debug("sent token")
        puts token
        Rails.logger.debug(token)
        if payload
          puts "sent payload"
          Rails.logger.debug(payload.inspect)
          puts payload.inspect
          current_user = User.find(payload[0]["user_id"])
          # current_user.store_getstream_token unless current_user.getstream_token
          @current_user = current_user # for some strange reason this is necessary so current_user is set
          request.env["warden"].set_user(current_user, store: false)
        else
          current_user = nil
          raise "Bearer Auth token failed authentication"
        end
      else
        Rails.logger.debug("no authorization token sent")
        Rails.logger.debug(request.headers["Authorization"])
        Rollbar.error("No authentication header sent", full_path: request.try(:fullpath), req_params: request.try(:request_parameters), query_params: request.try(:query_parameters))
        current_user = nil
        raise "No authentication header sent"
      end
    end

    rescue_from CanCan::AccessDenied do |exception|
      respond_to do |format|
        format.json { head :forbidden, content_type: "text/html" }
        format.html { redirect_to admin_not_authorized_path, notice: exception.message }
        format.js   { head :forbidden, content_type: "text/html" }
      end
    end

    rescue_from ActionController::InvalidAuthenticityToken do |exception|
      if Rails.env == "development"
        raise exception
      else
        Rails.logger.error "InvalidAuthenticityToken error detected. Request url: #{request.try(:url)}"
        head :no_content
      end
    end

    def raise_not_found
      if Rails.env != "development"
        Rails.logger.debug "No route matches #{params[:unmatched_route]}"
        head :no_content
      else
        raise ActionController::RoutingError.new("No route matches #{params[:unmatched_route]}")
      end
    end

    protected

      def configure_permitted_parameters
        added_attrs = [ :username, :social_handle, :referrer_id, :name, :email, :password, :password_confirmation, :phone, :ruc, :doc_type, :doc_number, :address, :district, :image, :interested_in, :birthday ]
        devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
        devise_parameter_sanitizer.permit :account_update, keys: added_attrs
      end

    private

      def set_app_version_header
        response.set_header("app-version", ENV["APP_VERSION"])
      end
  end
end
