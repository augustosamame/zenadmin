class Admin::UserAttendanceLogsController < Admin::AdminController
  before_action :set_user, only: [ :seller_checkout, :seller_checkin_status ]
  before_action :set_location, only: [ :seller_checkout, :seller_checkin_status ]

  def index
    if current_user.any_admin_or_supervisor?
      locations_ids = Location.all.pluck(:id)
      @user_attendance_logs = UserAttendanceLog.includes(:user, :location).where(location_id: locations_ids).order(status: :asc)
    else
      locations_ids = [ current_user.location_id ]
      @user_attendance_logs = UserAttendanceLog.includes(:user, :location).where(location_id: locations_ids).order(status: :asc)
    end
    @locations = Location.where(id: locations_ids)

    if params[:location_id].present?
      @user_attendance_logs = @user_attendance_logs.where(location_id: params[:location_id])
    end

    @datatable_options = "server_side:false;resource_name:'UserAttendanceLog';sort_4_asc;sort_1_asc;"

    respond_to do |format|
      format.html
      format.json { render json: @user_attendance_logs }
    end
  end

  def new
    @user_attendance_log = UserAttendanceLog.new
    set_form_variables
  end

  def create
    @user_attendance_log = UserAttendanceLog.new(user_attendance_log_params)
    existing_log = UserAttendanceLog.find_by(user: @user_attendance_log.user, location: @user_attendance_log.location, checkout: nil)

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
          format.html { redirect_to admin_user_attendance_logs_path, notice: "El vendedor ha hecho checkin en #{@user_attendance_log.location.name}"
          }
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

    unless user.photo.present?
      render json: { match: false, error: "El usuario no tiene una foto registrada. Por favor, actualice el perfil del usuario con una foto antes de intentar el check-in." }
    else

      client = Aws::Rekognition::Client.new(
        region: 'us-east-1',
        credentials: Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY_ID'],
          ENV['AWS_SECRET_ACCESS_KEY']
        )
      )

      Rails.logger.info "Client created"

      photo_data = captured_photo.split(',')[1] # Remove data URL prefix
      image_bytes = Base64.decode64(photo_data)

      begin
        Rails.logger.info "Detecting faces in captured image"
        detect_response = client.detect_faces({
          image: { bytes: image_bytes },
          attributes: ['DEFAULT']
        })

        if detect_response.face_details.empty?
          Rails.logger.info "No face detected in the captured image for user #{user.id}"
          return render json: { match: false, error: "No se detectó un rostro en la imagen capturada. Por favor, intente de nuevo." }
        end

        compare_response = client.compare_faces({
          source_image: { bytes: image_bytes },
          target_image: { bytes: Base64.decode64(user.photo.split(',')[1]) },
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
end
