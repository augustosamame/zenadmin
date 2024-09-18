class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionView::Template::Error, with: :render_not_found
  rescue_from ArgumentError, with: :handle_argument_error
  rescue_from ActionDispatch::Http::MimeNegotiation::InvalidType, with: :handle_invalid_mime_type

  helper Railsui::ThemeHelper

  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_railsui_demo_links

  def set_railsui_demo_links
    @railsui_demo_links = [
      :integrations,
      :team,
      :billing,
      :notifications,
      :settings,
      :activity,
      :profile,
      :people,
      :calendar,
      :assignments,
      :message,
      :messages,
      :project,
      :projects
    ]
  end

  def render_not_found
    if Rails.env.production?
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
    else
      raise
    end
  end

  def handle_argument_error(exception)
    if exception.message.include?("invalid byte sequence in UTF-8")
      Rails.logger.error "Encoding Error: #{exception.message}"
      render :head
    else
      # Re-raise if it's not an encoding error
      raise exception
    end
  end

  def handle_invalid_mime_type(exception)
    Rails.logger.error "Invalid MIME type error: #{exception.message}"
    respond_to do |format|
      format.any  { head :bad_request }
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: "text/html" }
      format.html { redirect_to not_authorized_path, notice: exception.message }
      format.js   { head :forbidden, content_type: "text/html" }
    end
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :avatar, :name, :email, :phone ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :avatar, :name ])
    end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
end
