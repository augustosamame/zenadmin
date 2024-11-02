class Admin::PaymentsController < Admin::AdminController
  include MoneyRails::ActionViewExtension

  def index
    respond_to do |format|
      format.html do
        if current_user.any_admin_or_supervisor?
          @payments = Payment.includes(:payment_method, payable: :user).all.order(id: :desc)
        else
          @payments = Payment.includes(:payment_method, payable: :user)
                             .for_location(@current_location)
                             .order(id: :desc)
        end

        if @payments.size > 500
          @datatable_options = "server_side:true;resource_name:'Payment';create_button:false;sort_0_desc;"
        else
          @datatable_options = "server_side:false;resource_name:'Payment';create_button:false;sort_0_desc;"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    @payment = Payment.includes(:payment_method, :payable).find(params[:id])
  end

  private

  def payment_params
    params.require(:payment).permit(
      :payment_method_id,
      :user_id,
      :payable_id,
      :payable_type,
      :amount,
      :currency,
      :payment_date,
      :comment,
      :status,
      :processor_transacion_id
    )
  end

  def datatable_json
    payments = if current_user.any_admin_or_supervisor?
                Payment.includes(:payment_method, payable: :user).order(id: :desc)
    else
                Payment.includes(:payment_method, payable: :user)
                      .for_location(@current_location)
                      .order(id: :desc)
    end

    # Apply search filter
    if params[:search][:value].present?
      payments = payments.joins(:user)
                        .where("users.first_name ILIKE :search OR users.last_name ILIKE :search OR payments.custom_id ILIKE :search",
                              search: "%#{params[:search][:value]}%")
    end

    # Apply sorting
    if params[:order].present?
      order_by = case params[:order]["0"][:column].to_i
      when 0 then "custom_id"
      when 1 then "payment_date"
      when 2 then "users.first_name"
      when 3 then "amount_cents"
      when 4 then "status"
      else "id"
      end
      direction = params[:order]["0"][:dir] == "desc" ? "desc" : "asc"
      payments = payments.reorder("#{order_by} #{direction}")
    end

    # Pagination
    payments = payments.page(params[:start].to_i / params[:length].to_i + 1)
                      .per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: Payment.count,
      recordsFiltered: payments.total_count,
      data: payments.map do |payment|
        [
          payment.custom_id,
          friendly_date(current_user, payment.payment_date),
          payment.user.name,
          payment.payment_method.name,
          format_currency(payment.amount),
          payment.translated_status,
          payment.payable_type,
          payment.payable&.custom_id,
          render_to_string(
            partial: "admin/payments/actions",
            formats: [ :html ],
            locals: {
              payment: payment,
              default_object_options_array: @default_object_options_array
            }
          )
        ]
      end
    }
  end
end
