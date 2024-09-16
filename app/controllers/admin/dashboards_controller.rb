class Admin::DashboardsController < Admin::AdminController
  def admin_dashboard
    set_sales_count_variables
    set_sales_amount_variables
    set_sales_amount_this_month_variables
  end

  def sales_dashboard
  end

  private

    def set_sales_count_variables
      @sales_count = Order.where(order_date: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).count
      sales_count_yesterday = Order.where(order_date: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).count || 0
      sales_count_change_since_yesterday = @sales_count - sales_count_yesterday
      if sales_count_change_since_yesterday > 0
        @sales_count_change_since_yesterday = "+#{sales_count_change_since_yesterday}"
      else
        @sales_count_change_since_yesterday = "-#{sales_count_change_since_yesterday}"
      end

      sales_count_last_month = Order.where(order_date: 1.month.ago.beginning_of_day..1.month.ago.end_of_day).count || 0
      sales_count_change_since_last_month = @sales_count - sales_count_last_month
      if sales_count_change_since_last_month > 0
        @sales_count_change_since_last_month = "+#{sales_count_change_since_last_month}"
      else
        @sales_count_change_since_last_month = "-#{sales_count_change_since_last_month}"
      end
    end

    def set_sales_amount_variables
      @sales_amount = Order.where(order_date: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).sum(:total_price_cents) / 100
      sales_amount_yesterday = Order.where(order_date: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).sum(:total_price_cents) / 100 || 0
      sales_amount_change_since_yesterday = @sales_amount - sales_amount_yesterday
      if sales_amount_change_since_yesterday > 0
        @sales_amount_change_since_yesterday = "+#{sales_amount_change_since_yesterday}"
      else
        @sales_amount_change_since_yesterday = "-#{sales_amount_change_since_yesterday}"
      end

      sales_amount_last_month = Order.where(order_date: 1.month.ago.beginning_of_day..1.month.ago.end_of_day).sum(:total_price_cents) / 100 || 0
      sales_amount_change_since_last_month = @sales_amount - sales_amount_last_month
      if sales_amount_change_since_last_month > 0
        @sales_amount_change_since_last_month = "+#{sales_amount_change_since_last_month}"
      else
        @sales_amount_change_since_last_month = "-#{sales_amount_change_since_last_month}"
      end
    end

    def set_sales_amount_this_month_variables
      @sales_amount_this_month = Order.where(order_date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month).sum(:total_price_cents) / 100
      @sales_amount_last_month = Order.where(order_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).sum(:total_price_cents) / 100 || 0
      @sales_amount_change_since_last_month = @sales_amount_this_month - @sales_amount_last_month
      if @sales_amount_change_since_last_month > 0
        @sales_amount_change_since_last_month = "+#{@sales_amount_change_since_last_month}"
      else
        @sales_amount_change_since_last_month = "-#{@sales_amount_change_since_last_month}"
      end
    end
end
