class Admin::SellerBiweeklySalesTargetsController < Admin::AdminController
  before_action :set_seller_biweekly_sales_target, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, SellerBiweeklySalesTarget
    @seller_biweekly_sales_targets = SellerBiweeklySalesTarget.all.includes([ :seller, :location ])
  end

  def show
    authorize! :read, @seller_biweekly_sales_target
  end

  def new
    authorize! :create, SellerBiweeklySalesTarget
    @seller_biweekly_sales_target = SellerBiweeklySalesTarget.new
  end

  def create
    authorize! :create, SellerBiweeklySalesTarget
    success = true

    if params[:seller_biweekly_sales_target][:targets].present?
      params[:seller_biweekly_sales_target][:targets].each do |target_params|
        @seller_biweekly_sales_target = SellerBiweeklySalesTarget.new(
          seller_id: params[:seller_biweekly_sales_target][:seller_id],
          year_month_period: params[:seller_biweekly_sales_target][:year_month_period],
          location_id: target_params[:location_id],
          sales_target: target_params[:sales_target],
          target_commission: target_params[:target_commission],
          status: params[:seller_biweekly_sales_target][:status],
          user: current_user
        )

        unless @seller_biweekly_sales_target.save
          success = false
          break
        end
      end
    end

    if success
      redirect_to admin_seller_biweekly_sales_targets_path,
        notice: "Metas Quincenales por Vendedor fueron creadas exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @seller_biweekly_sales_target
    # Find all targets for this seller and period
    @seller_biweekly_sales_targets = SellerBiweeklySalesTarget.includes(:seller).where(
      seller_id: @seller_biweekly_sales_target.seller_id,
      year_month_period: @seller_biweekly_sales_target.year_month_period
    )
  end

  def update
    authorize! :update, @seller_biweekly_sales_target
    success = true

    # Find all existing targets for this seller and period
    existing_targets = SellerBiweeklySalesTarget.where(
      seller_id: @seller_biweekly_sales_target.seller_id,
      year_month_period: @seller_biweekly_sales_target.year_month_period
    )

    ActiveRecord::Base.transaction do
      # Delete existing targets that aren't in the new targets array
      if params[:seller_biweekly_sales_target][:targets].present?
        new_location_ids = params[:seller_biweekly_sales_target][:targets].map { |t| t[:location_id].to_i }
        existing_targets.where.not(location_id: new_location_ids).destroy_all

        # Update or create targets
        params[:seller_biweekly_sales_target][:targets].each do |target_params|
          target = existing_targets.find_or_initialize_by(
            location_id: target_params[:location_id],
            seller_id: @seller_biweekly_sales_target.seller_id,
            year_month_period: @seller_biweekly_sales_target.year_month_period
          )

          target.assign_attributes(
            sales_target: target_params[:sales_target],
            target_commission: target_params[:target_commission],
            status: params[:seller_biweekly_sales_target][:status],
            user: current_user
          )

          unless target.save
            success = false
            raise ActiveRecord::Rollback
          end
        end
      else
        # If no targets provided, remove all existing targets
        existing_targets.destroy_all
        success = false
      end
    end

    if success
      redirect_to admin_seller_biweekly_sales_targets_path,
        notice: "Metas Quincenales por Vendedor fueron actualizadas exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @seller_biweekly_sales_target
    @seller_biweekly_sales_target.destroy
    redirect_to admin_seller_biweekly_sales_targets_path, notice: "Metas Quincenales por Vendedor fueron eliminadas exitosamente."
  end

  def seller_data
    authorize! :read, SellerBiweeklySalesTarget
    seller = User.find(params[:seller_id])
    reference_periods = params[:reference_periods].to_i
    current_period = SellerBiweeklySalesTarget.generate_year_month_period(Date.current)

    data = []
    reference_periods.times do |i|
      date = Date.current - i.months
      [ "II", "I" ].each do |period|
        year_month_period = "#{date.year}_#{date.month.to_s.rjust(2, '0')}_#{period}"
        next if year_month_period >= current_period # Skip current and future periods

        sales_service = Services::Queries::SalesSearchService.new(seller: seller, year_month_period: year_month_period)
        seller_sales_by_location = sales_service.sales_for_period_and_seller

        # Get all location IDs where seller had sales
        location_ids = seller_sales_by_location.map { |s| s[:location_id] }

        # Get total sales for each location
        location_total_sales = sales_service.sales_for_period_and_location(location_ids)

        # Combine the data
        seller_sales_by_location.each do |location_data|
          data << {
            year_month_period: year_month_period,
            location_id: location_data[:location_id],
            location_name: location_data[:location_name],
            sales: location_data[:seller_sales],
            location_sales: location_total_sales[location_data[:location_id]]
          }
        end

        break if data.size >= reference_periods
      end
      break if data.size >= reference_periods
    end

    render json: data
  end

  private

  def set_seller_biweekly_sales_target
    @seller_biweekly_sales_target = SellerBiweeklySalesTarget.find(params[:id])
  end

  def seller_biweekly_sales_target_params
    params.require(:seller_biweekly_sales_target).permit(
      :seller_id,
      :year_month_period,
      :status,
      targets: [ :location_id, :sales_target, :target_commission ]
    )
  end

  def get_previous_period(year_month_period)
    year, month, period = year_month_period.split("_")
    date = Date.new(year.to_i, month.to_i, period == "I" ? 1 : 16)
    SellerBiweeklySalesTarget.generate_year_month_period(date - 15.days)
  end
end
