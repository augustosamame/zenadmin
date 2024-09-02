class Admin::SellerBiweeklySalesTargetsController < Admin::AdminController
  before_action :set_seller_biweekly_sales_target, only: [ :show, :edit, :update, :destroy ]

  def index
    @seller_biweekly_sales_targets = SellerBiweeklySalesTarget.all
  end

  def show
  end

  def new
    @seller_biweekly_sales_target = SellerBiweeklySalesTarget.new
  end

  def create
    @seller_biweekly_sales_target = SellerBiweeklySalesTarget.new(seller_biweekly_sales_target_params)
    @seller_biweekly_sales_target.user = current_user

    if @seller_biweekly_sales_target.save
      redirect_to admin_seller_biweekly_sales_target_path(@seller_biweekly_sales_target), notice: "Seller biweekly sales target was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @seller_biweekly_sales_target.update(seller_biweekly_sales_target_params)
      redirect_to admin_seller_biweekly_sales_target_path(@seller_biweekly_sales_target), notice: "Seller biweekly sales target was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @seller_biweekly_sales_target.destroy
    redirect_to admin_seller_biweekly_sales_targets_path, notice: "Seller biweekly sales target was successfully destroyed."
  end

  def seller_data
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
        data << {
          year_month_period: year_month_period,
          sales: sales_service.sales_for_period_and_seller,
          location_sales: sales_service.sales_for_period_and_location(seller.location)
        }

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
    params.require(:seller_biweekly_sales_target).permit(:seller_id, :year_month_period, :sales_target_cents, :target_commission, :status)
  end

  def get_previous_period(year_month_period)
    year, month, period = year_month_period.split("_")
    date = Date.new(year.to_i, month.to_i, period == "I" ? 1 : 16)
    SellerBiweeklySalesTarget.generate_year_month_period(date - 15.days)
  end
end
