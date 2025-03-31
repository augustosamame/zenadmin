class Admin::CommissionsController < Admin::AdminController
  def index
    respond_to do |format|
      format.html do
        @seller = User.find(params[:seller_id]) if params[:seller_id].present?

        # Extract filter parameters
        filter_params = {}
        
        if params[:filter].is_a?(String)
          # Handle the case where filter is a string (from location dropdown)
          Rails.logger.debug "Filter is a string: #{params[:filter]}"
          # Try to parse the string format "from_date VALUE to_date VALUE status_paid_out VALUE"
          filter_string = params[:filter]
          
          # Extract from_date
          from_date_match = filter_string.match(/from_date\s+(\S+)/)
          filter_params["from_date"] = from_date_match[1] if from_date_match
          
          # Extract to_date
          to_date_match = filter_string.match(/to_date\s+(\S+)/)
          filter_params["to_date"] = to_date_match[1] if to_date_match
          
          # Extract status_paid_out
          status_match = filter_string.match(/status_paid_out\s+(\S+)/)
          filter_params["status_paid_out"] = status_match[1] if status_match
        else
          # Normal case - filter is a hash
          filter_params = params[:filter] || {}
        end
        
        Rails.logger.debug "FILTER PARAMS: #{filter_params}"

        # Use @current_location which is set by LocationManageable concern
        # We don't need to set session[:commission_location_id] as LocationManageable 
        # already sets session[:current_location_id]
        @location_id = @current_location&.id
        Rails.logger.debug "LOCATION_ID: #{@location_id}, Current Location: #{@current_location&.name}"

        # Set date filters from params or session
        if filter_params["from_date"].present?
          @from_date = filter_params["from_date"]
          session[:commission_from_date] = @from_date
          Rails.logger.debug "Setting from_date from params: #{@from_date}"
        elsif session[:commission_from_date].present?
          @from_date = session[:commission_from_date]
          Rails.logger.debug "Setting from_date from session: #{@from_date}"
        else
          @from_date = Date.today.beginning_of_month.to_s
          session[:commission_from_date] = @from_date
          Rails.logger.debug "Setting default from_date: #{@from_date}"
        end

        if filter_params["to_date"].present?
          @to_date = filter_params["to_date"]
          session[:commission_to_date] = @to_date
          Rails.logger.debug "Setting to_date from params: #{@to_date}"
        elsif session[:commission_to_date].present?
          @to_date = session[:commission_to_date]
          Rails.logger.debug "Setting to_date from session: #{@to_date}"
        else
          @to_date = Date.today.to_s
          session[:commission_to_date] = @to_date
          Rails.logger.debug "Setting default to_date: #{@to_date}"
        end

        # Handle status_paid_out filter
        if filter_params.key?("status_paid_out")
          status_value = filter_params["status_paid_out"]
          @status_paid_out = status_value.to_s == "true" || status_value.to_s == "1"
          session[:commission_status_paid_out] = @status_paid_out
          Rails.logger.debug "Setting session status_paid_out: #{session[:commission_status_paid_out]} from value: #{status_value} (#{status_value.class})"
        else
          @status_paid_out = session[:commission_status_paid_out]
        end

        Rails.logger.debug "SESSION VALUES: from_date=#{session[:commission_from_date]}, to_date=#{session[:commission_to_date]}, status_paid_out=#{session[:commission_status_paid_out]}"
        Rails.logger.debug "INSTANCE VALUES: from_date=#{@from_date}, to_date=#{@to_date}, status_paid_out=#{@status_paid_out}"

        # Set up data for view
        @locations = Location.active.order(:name)
        @sellers = User.active.where(role: [:seller, :admin, :supervisor]).order(:name)

        # Base query with necessary includes
        @commissions = if current_user.any_admin_or_supervisor?
          base_query = Commission.includes([ :user, :order, order: :location ])

          # Apply location filter if a specific location is selected
          if @location_id.present? && @location_id != "all"
            base_query = base_query.joins(order: :location).where(orders: { location_id: @location_id })
          end

          base_query
        else
          # For non-admin users, always filter by their current location
          Commission.joins(order: :location).where(orders: { location: @current_location }).includes([ :user, :order, order: :location ])
        end

        # Apply date filter
        if @from_date && @to_date
          @commissions = @commissions.where("DATE(commissions.created_at) BETWEEN ? AND ?", @from_date, @to_date)
        end

        # If status_paid_out is checked, exclude unpaid commissions
        if @status_paid_out
          @commissions = @commissions.where(status: "paid_out")
        end

        # Only load a limited set of commissions for the initial page load
        @commissions = @commissions.order(id: :desc).limit(10)

        @datatable_options = "server_side:true;resource_name:'Commission';create_button:false;sort_0_desc;hide_0;date_filter:true"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    @commission = Commission.find(params[:id])
  end

  private

  def datatable_json
    Rails.logger.debug "DATATABLE SESSION START: #{session.to_h.select { |k, _| k.to_s.start_with?('commission_') }}"
    Rails.logger.debug "DATATABLE PARAMS: #{params.to_unsafe_h}"

    # Extract filter parameters
    filter_params = {}
    
    if params[:filter].is_a?(String)
      # Handle the case where filter is a string (from location dropdown)
      Rails.logger.debug "Filter is a string: #{params[:filter]}"
      # Try to parse the string format "from_date VALUE to_date VALUE status_paid_out VALUE"
      filter_string = params[:filter]
      
      # Extract from_date
      from_date_match = filter_string.match(/from_date\s+(\S+)/)
      filter_params["from_date"] = from_date_match[1] if from_date_match
      
      # Extract to_date
      to_date_match = filter_string.match(/to_date\s+(\S+)/)
      filter_params["to_date"] = to_date_match[1] if to_date_match
      
      # Extract status_paid_out
      status_match = filter_string.match(/status_paid_out\s+(\S+)/)
      filter_params["status_paid_out"] = status_match[1] if status_match
    elsif params[:filterParams].present?
      # Handle the case where parameters are in filterParams (from JavaScript)
      filter_params = params[:filterParams]
    else
      # Normal case - filter is a hash
      filter_params = params[:filter] || {}
    end
    
    Rails.logger.debug "DATATABLE FILTER PARAMS: #{filter_params}"

    # Store filter values in session for persistence
    if filter_params["from_date"].present?
      session[:commission_from_date] = filter_params["from_date"]
    end

    if filter_params["to_date"].present?
      session[:commission_to_date] = filter_params["to_date"]
    end

    if filter_params.key?("status_paid_out")
      status_value = filter_params["status_paid_out"]
      session[:commission_status_paid_out] = status_value.to_s == "true" || status_value.to_s == "1"
    end

    # Check for location filter
    location_id = @current_location&.id
    
    Rails.logger.debug "DATATABLE LOCATION_ID: #{location_id}, Current Location: #{@current_location&.name}"

    # Base query with necessary includes
    commissions = if current_user.any_admin_or_supervisor?
      if location_id.present?
        Commission.includes(:user, order: :location).joins(order: :location).where(orders: { location_id: location_id })
      else
        Commission.includes(:user, order: :location)
      end
    else
      Commission.includes(:user, order: :location).where(user_id: current_user.id)
    end

    # Apply search filter if provided
    if params[:search][:value].present?
      search_term = "%#{params[:search][:value]}%"
      commissions = commissions.joins(:user, :order).where(
        "users.name ILIKE ? OR orders.custom_id ILIKE ?",
        search_term, search_term
      )
    end

    # Apply date filter
    from_date = filter_params["from_date"] || session[:commission_from_date]
    to_date = filter_params["to_date"] || session[:commission_to_date]

    Rails.logger.debug "DATATABLE DATE FILTER: from_date=#{from_date}, to_date=#{to_date}"

    if from_date.present? && to_date.present?
      commissions = commissions.where("DATE(commissions.created_at) BETWEEN ? AND ?", from_date, to_date)
    end

    # Convert status_paid_out to boolean properly
    status_paid_out = if filter_params["status_paid_out"].present?
                       status_value = filter_params["status_paid_out"]
                       status_value.to_s == "true" || status_value.to_s == "1"
                     else
                       session[:commission_status_paid_out]
                     end

    Rails.logger.debug "DATATABLE STATUS FILTER: status_paid_out=#{status_paid_out}"

    # Filter by status if status_paid_out is true
    if status_paid_out
      commissions = commissions.where(status: "status_paid_out")
    end

    # Get total count before pagination
    total_records = commissions.count

    # Apply pagination
    start = params[:start].to_i
    length = params[:length].to_i
    if length <= 0
      commissions = commissions.offset(start)
    else
      commissions = commissions.offset(start).limit(length)
    end

    # Format data for datatable
    data = commissions.map do |commission|
      [
        commission.id,
        commission.user.name,
        helpers.friendly_date(current_user, commission.created_at, false),
        commission.order.location.name,
        "#{helpers.seller_comission_percentage(commission.order.location)}%",
        commission.order.custom_id,
        helpers.format_currency(commission.order.total_price - commission.order.total_discount),
        "#{commission.percentage}%",
        helpers.format_currency((commission.order.total_price - commission.order.total_discount) * commission.percentage / 100),
        helpers.format_currency(commission.amount),
        commission.status == "status_paid_out" ? "Pagada" : "Pendiente"
      ]
    end

    # Return JSON response in the format expected by DataTables
    return {
      draw: params[:draw].to_i,
      recordsTotal: total_records,
      recordsFiltered: total_records,
      data: data
    }
  end
end
