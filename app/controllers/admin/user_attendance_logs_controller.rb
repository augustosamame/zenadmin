class Admin::UserAttendanceLogsController < Admin::AdminController
  before_action :set_user, only: [ :seller_checkout, :seller_checkin_status ]
  before_action :set_location, only: [ :seller_checkout, :seller_checkin_status ]

  def index
    # Check if we need to clear filters
    if params[:clear_filters].present?
      clear_session_filters
      redirect_to admin_user_attendance_logs_path and return
    end

    # Get locations based on user role
    if current_user.any_admin_or_supervisor?
      locations_ids = Location.all.pluck(:id)
    else
      locations_ids = [ current_user.location_id ]
    end
    @locations = Location.where(id: locations_ids)

    # Set filter values for the view (from params or session)
    @filter_location_id = params[:location_id].presence || session[:user_attendance_filter_location_id].presence
    @filter_begin_datetime = params[:begin_datetime].presence || session[:user_attendance_filter_begin_datetime].presence
    @filter_end_datetime = params[:end_datetime].presence || session[:user_attendance_filter_end_datetime].presence

    respond_to do |format|
      format.html do
        # Build datatable options with server-side processing
        @datatable_options = "server_side:true;resource_name:'UserAttendanceLog';ajax_url:'#{admin_user_attendance_logs_path(format: :json)}';sort_4_asc;sort_1_asc;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def new
    @user_attendance_log = UserAttendanceLog.new
    set_form_variables
  end

  def create
    @user_attendance_log = UserAttendanceLog.new(user_attendance_log_params)
    
    # Look for existing logs that are NOT just created (add a time buffer)
    # This prevents accidentally checking out a log that was just created
    existing_log = UserAttendanceLog.where(
      user: @user_attendance_log.user, 
      location: @user_attendance_log.location, 
      checkout: nil
    ).where("created_at < ?", 30.seconds.ago).first

    if existing_log
      if existing_log.update(checkout: Time.current)
        respond_to do |format|
          format.html { redirect_to admin_user_attendance_logs_path, notice: "El vendedor ha hecho checkout en #{existing_log.location.name}" }
          format.json { render json: { message: "El vendedor ha hecho checkout en #{existing_log.location.name}" } }
        end
      else
        set_form_variables
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: existing_log.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    else
      if @user_attendance_log.save
        respond_to do |format|
          format.html { redirect_to admin_user_attendance_logs_path, notice: "El vendedor ha hecho checkin en #{@user_attendance_log.location.name}" }
          format.json { render json: { message: "El vendedor ha hecho checkin en #{@user_attendance_log.location.name}" }, status: :created }
        end
      else
        set_form_variables
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @user_attendance_log.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end
  end

  def compare_face
    Rails.logger.info "Comparing face for user #{params[:user_attendance_log][:user_id]}"
    user = User.find(params[:user_attendance_log][:user_id])
    captured_photo = params[:user_attendance_log][:captured_photo]

    unless user.user_seller_photo&.seller_photo.present?
      render json: { match: false, error: "El usuario no tiene una foto registrada. Por favor, actualice el perfil del usuario con una foto antes de intentar el check-in." }
    else

      client = Aws::Rekognition::Client.new(
        region: "us-east-1",
        credentials: Aws::Credentials.new(
          ENV["AWS_REKOGNITION_ACCESS_KEY_ID"],
          ENV["AWS_REKOGNITION_SECRET_ACCESS_KEY"]
        )
      )

      Rails.logger.info "Client created"

      photo_data = captured_photo.split(",")[1] # Remove data URL prefix
      image_bytes = Base64.decode64(photo_data)

      begin
        Rails.logger.info "Detecting faces in captured image"
        detect_response = client.detect_faces({
          image: { bytes: image_bytes },
          attributes: [ "DEFAULT" ]
        })

        if detect_response.face_details.empty?
          Rails.logger.info "No face detected in the captured image for user #{user.id}"
          return render json: { match: false, error: "No se detectó un rostro en la imagen capturada. Por favor, intente de nuevo." }
        end

        compare_response = client.compare_faces({
          source_image: { bytes: image_bytes },
          target_image: { bytes: Base64.decode64(user.user_seller_photo.seller_photo.split(",")[1]) },
          similarity_threshold: 90.0
        })

        Rails.logger.info "Response: #{compare_response.inspect}"

        if compare_response.face_matches.any?
          Rails.logger.info "Face match found for user #{user.id}"
          render json: { match: true }
        else
          Rails.logger.info "No face match found for user #{user.id}"
          render json: { match: false, error: "El rostro capturado no coincide con el registrado. Por favor, intente de nuevo." }
        end
      rescue Aws::Rekognition::Errors::ServiceError => e
        Rails.logger.error "Error comparing faces: #{e.message}"
        render json: { match: false, error: "Ocurrió un error durante la comparación facial" }, status: :internal_server_error
      end
    end
  end

  def edit
    @user_attendance_log = UserAttendanceLog.find(params[:id])
    set_form_variables
    @current_time = @user_attendance_log.checkin.strftime("%Y-%m-%dT%H:%M")
  end

  def update
    @user_attendance_log = UserAttendanceLog.find(params[:id])
    if @user_attendance_log.update(user_attendance_log_update_params)
      redirect_to admin_user_attendance_logs_path, notice: "El registro de asistencia se ha actualizado correctamente."
    else
      set_form_variables
      render :edit, status: :unprocessable_entity
    end
  end

  def seller_checkout
    user_attendance_log = @user.user_attendance_logs.current.first

    if user_attendance_log
      user_attendance_log.update(checkout: Time.current)
      @user.update(location: nil)
      respond_to do |format|
        format.html { redirect_to admin_user_attendance_logs_path, notice: "El vendedor ha hecho checkout en #{user_attendance_log.location.name}" }
        format.json { render json: { message: "El vendedor ha hecho checkout en #{user_attendance_log.location.name}" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_user_attendance_logs_path, alert: "El vendedor no tiene un checkin activo" }
        format.json { render json: { error: "El vendedor no tiene un checkin activo" }, status: :not_found }
      end
    end
  end

  def check_attendance_status
    location_id = params[:location_id]
    user_id = params[:user_id]

    attendance_log = UserAttendanceLog.find_by(location_id: location_id, user_id: user_id, checkout: nil)

    if attendance_log
      render json: {
        has_open_attendance: true,
        checkin_time: attendance_log.checkin.strftime("%Y-%m-%dT%H:%M")
      }
    else
      render json: { has_open_attendance: false }
    end
  end

  def seller_checkin_status
    status = user.location == location && user.user_attendance_logs.current.exists?

    respond_to do |format|
      format.html { render :seller_checkin_status, locals: { checked_in: status } }
      format.json { render json: { checked_in: status } }
    end
  end

  def location_sellers
    @users = location.users.joins(:user_attendance_logs).where(user_attendance_logs: { checkout: nil }).distinct

    respond_to do |format|
      format.html { render :location_sellers }
      format.json { render json: @users }
    end
  end

  def seller_attendance_report
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date
    user = User.find(params[:user_id])

    attendance_service = Services::Attendance::AttendanceService.new(user)
    @attendance_report = attendance_service.generate_user_attendance_report(start_date, end_date)

    respond_to do |format|
      format.html { render :seller_attendance_report }
      format.json { render json: @attendance_report }
    end
  end

  def location_attendance_report
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    attendance_service = Services::Attendance::AttendanceService.new
    @attendance_report = attendance_service.generate_location_attendance_report(start_date, end_date)

    respond_to do |format|
      format.html { render :location_attendance_report }
      format.json { render json: @attendance_report }
    end
  end

  private

    def set_form_variables
      @user_is_admin_or_supervisor = current_user.any_admin_or_supervisor?
      @current_time = Time.current.strftime("%Y-%m-%dT%H:%M")
      @elligible_locations = current_user.any_admin_or_supervisor? ? Location.all : Location.where(id: current_user.location_id)
      @elligible_sellers = User.with_role("seller").where(internal: false).distinct
      @already_checked_in_users = User.with_role("seller")
                                    .where(internal: false)
                                    .joins(:user_attendance_logs)
                                    .where(user_attendance_logs: { checkout: nil })
                                    .distinct
    end

    def user_attendance_log_params
      params.require(:user_attendance_log).permit(:user_id, :location_id, :checkin, :checkout)
    end

    def user_attendance_log_update_params
      params.require(:user_attendance_log).permit(:checkin, :checkout)
    end

    def set_user
      @user = User.find(params[:user_id])
    end

    def set_location
      @location = Location.find(params[:location_id])
    end

    def clear_session_filters
      session.delete(:user_attendance_filter_location_id)
      session.delete(:user_attendance_filter_begin_datetime)
      session.delete(:user_attendance_filter_end_datetime)
      Rails.logger.debug "All session filters cleared"
    end

    def apply_filters(scope)
      # Store filter values in session for persistence (only if they are present)
      session[:user_attendance_filter_location_id] = params[:location_id] if params[:location_id].present?
      session[:user_attendance_filter_begin_datetime] = params[:begin_datetime] if params[:begin_datetime].present?
      session[:user_attendance_filter_end_datetime] = params[:end_datetime] if params[:end_datetime].present?

      # Debug the session values
      Rails.logger.debug "Session filters: location=#{session[:user_attendance_filter_location_id].inspect}, begin=#{session[:user_attendance_filter_begin_datetime].inspect}, end=#{session[:user_attendance_filter_end_datetime].inspect}"

      # Apply location filter (only if there's an actual value)
      location_id = params[:location_id].presence || session[:user_attendance_filter_location_id].presence
      if location_id.present?
        Rails.logger.debug "Applying location filter: #{location_id}"
        scope = scope.where(location_id: location_id)
      end

      # Apply begin date filter (only if there's an actual value)
      begin_date = params[:begin_datetime].presence || session[:user_attendance_filter_begin_datetime].presence
      if begin_date.present?
        Rails.logger.debug "Applying begin date filter: #{begin_date}"
        scope = scope.where("checkin >= ?", begin_date)
      end

      # Apply end date filter (only if there's an actual value)
      end_date = params[:end_datetime].presence || session[:user_attendance_filter_end_datetime].presence
      if end_date.present?
        Rails.logger.debug "Applying end date filter: #{end_date}"
        scope = scope.where("checkin <= ?", end_date)
      end

      scope
    end

    def datatable_json
      # Get locations based on user role
      if current_user.any_admin_or_supervisor?
        locations_ids = Location.all.pluck(:id)
      else
        locations_ids = [ current_user.location_id ]
      end

      # Store filter values in session for persistence (only if they are present)
      session[:user_attendance_filter_location_id] = params[:location_id] if params[:location_id].present?
      session[:user_attendance_filter_begin_datetime] = params[:begin_datetime] if params[:begin_datetime].present?
      session[:user_attendance_filter_end_datetime] = params[:end_datetime] if params[:end_datetime].present?

      # Base query with includes for performance
      base_query = UserAttendanceLog.includes(:user, :location)
                                .where(location_id: locations_ids)

      # Apply filters
      filtered_logs = apply_filters(base_query)

      # Debug log to check if we have records
      Rails.logger.debug "Found #{filtered_logs.count} logs after filtering"

      # Format the response for DataTables
      {
        draw: params[:draw].to_i,
        recordsTotal: UserAttendanceLog.where(location_id: locations_ids).count,
        recordsFiltered: filtered_logs.count,
        data: filtered_logs.map do |log|
          [
            log.user.name,
            log.location.name,
            log.checkin.strftime("%d/%m/%Y %H:%M"),
            log.checkout&.strftime("%d/%m/%Y %H:%M") || '',
            log.checkout.nil? ? 'Activo' : 'Cerrado',
            "<a href=\"#{edit_admin_user_attendance_log_path(log)}\" class=\"btn btn-sm btn-primary\"><i class=\"fas fa-pencil-alt\"></i></a>"
          ]
        end
      }
    end

    def filter_params
      params.permit(:location_id, :begin_datetime, :end_datetime).to_h
    end
end
