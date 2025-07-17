class Admin::CustomersController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::CaptureHelper
  def index
    respond_to do |format|
      format.html do
        # Load only a small subset of customers for initial page load
        @users = User.customers
                     .includes(:loyalty_tier, customer: :price_list)
                     .select("users.*,
                              COUNT(DISTINCT orders.id) as orders_count,
                              COALESCE(SUM(orders.total_price_cents), 0) as total_order_amount_cents")
                     .left_joins(:orders)
                     .group("users.id")
                     .order(id: :desc)
                     .limit(10)
        @datatable_options = "server_side:true;resource_name:'Customer';hide_0;sort_0_desc;"
      end
      format.json do
        # Check if it's a datatable request
        if params[:draw].present?
          render json: datatable_json
        else
          @customers = User.customers.limit(1000)
          # query for customers modal in pos
          render json: @customers.select(:id, :first_name, :last_name, :email, :phone, :user_id)
        end
      end
      format.turbo_stream do
        # Check if the request is coming from the POS modal
        in_modal = request.referer&.include?("/admin/orders/pos") || params[:in_modal].present?
        
        render turbo_stream: turbo_stream.replace("switchable-container", partial: "admin/customers/table", locals: { customers: optimized_customers_for_modal, in_modal: in_modal })
      end
    end
  end


  def new
    @user = User.new
    @user.build_customer

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("switchable-container", partial: "admin/customers/form", locals: { in_modal: params[:in_modal] })
      end
    end
  end

  def create
    @user = User.new(user_params)
    @user.add_role("customer")
    @user.password ||= SecureRandom.alphanumeric(8)
    respond_to do |format|
      if @user.save
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("switchable-container", partial: "admin/customers/table", locals: { customers: optimized_customers_for_modal, in_modal: params[:in_modal] }),
            turbo_stream.append("switchable-container",
              "<script>document.dispatchEvent(new CustomEvent('customer-form-result', { detail: { success: true } }))</script>"
            )
          ]
        }
      else
        format.html { render :new }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace(
              "switchable-container",
              partial: "admin/customers/form",
              locals: { in_modal: params[:in_modal], user: @user }
            ),
          turbo_stream.append("switchable-container",
            "<script>document.dispatchEvent(new CustomEvent('customer-form-result', { detail: { success: false } }))</script>"
          )
          ]
        }
      end
    end
  end

  def show
    @customer = Customer.find(params[:id])
    render json: @customer
  end

  def edit
    @user = User.includes(:customer).find(params[:id])
    @customer = @user.customer || @user.build_customer
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_customers_path, notice: "Cliente actualizado correctamente"
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      redirect_to admin_customers_path, notice: "Cliente eliminado correctamente"
    else
      redirect_to admin_customers_path, alert: "El cliente no pudo ser eliminado"
    end
  end

  def search_dni
    response = Services::ReniecSunat::ConsultaDniRucPerudevs.consultar_dni(params[:numero])
    if response["estado"] == false
      render json: { nombres: "", apellido_paterno: "", apellido_materno: "", fecha_nacimiento: "" }.to_json
    else
      if response["mensaje"] && response["mensaje"] == "Encontrado" && response["resultado"].present?
        capitalized_response = response["resultado"].transform_values do |value|
          value.split.map(&:capitalize).join(" ") if value.is_a?(String)
        end
        render json: capitalized_response
      else
        render json: { error: "No se encontraron datos para el DNI ingresado" }
      end
    end
  end

  def search_ruc
    response = Services::ReniecSunat::ConsultaDniRucPerudevs.consultar_ruc(params[:numero])
    if response["mensaje"] && response["mensaje"] == "Encontrado" && response["resultado"].present?
      capitalized_response = response["resultado"].transform_values do |value|
        value.split.map(&:capitalize).join(" ") if value.is_a?(String)
      end
      render json: capitalized_response
    else
      render json: { error: "No se encontraron datos para el RUC ingresado" }
    end
  end

  private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone, customer_attributes: [ :id, :doc_type, :doc_id, :birthdate, :wants_factura, :factura_ruc, :factura_razon_social, :dni_address, :factura_direccion, :price_list_id, :_destroy ])
    end

    def optimized_customers_for_modal
      Customer.includes(:user, :price_list)
              .joins(:user)
              .merge(User.customers)
              .limit(1000)  # Reasonable limit for modal display
              .order('users.id DESC')
    end
    
    def datatable_json
      base_query = User.customers
                       .joins(:customer)
                       .select("users.*,
                               customers.doc_id,
                               customers.doc_type,
                               customers.factura_ruc,
                               customers.factura_razon_social,
                               customers.price_list_id,
                               COUNT(DISTINCT orders.id) as orders_count,
                               COALESCE(SUM(orders.total_price_cents), 0) as total_order_amount_cents")
                       .left_joins(:orders)
                       .group("users.id, users.first_name, users.last_name, users.email, users.phone, users.status, users.loyalty_tier_id, users.created_at, users.updated_at, customers.id, customers.doc_id, customers.doc_type, customers.factura_ruc, customers.factura_razon_social, customers.price_list_id")

      # Apply search filter
      if params[:search][:value].present?
        search_term = "%#{params[:search][:value]}%"
        base_query = base_query.where("users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ? OR users.phone ILIKE ? OR customers.doc_id ILIKE ? OR customers.factura_ruc ILIKE ?", 
                                      search_term, search_term, search_term, search_term, search_term, search_term)
      end

      users = base_query

      # Apply sorting
      if params[:order].present?
        column_index = params[:order]["0"][:column].to_i
        direction = params[:order]["0"][:dir]

        order_clause = case column_index
        when 0
          [ "users.id", direction ]
        when 1
          [ [ "users.first_name", "users.last_name" ], direction ]
        when 2
          [ "users.email", direction ]
        when 3
          [ "users.phone", direction ]
        when 4
          [ "customers.doc_type", direction ]
        when 5
          [ "COALESCE(customers.doc_id, customers.factura_ruc)", direction ]
        when 6
          if $global_settings[:feature_flag_price_lists]
            users = users.joins("LEFT JOIN price_lists ON price_lists.id = customers.price_list_id")
            [ "price_lists.name", direction ]
          else
            [ "users.id", "DESC" ]
          end
        when 7
          users = users.joins("LEFT JOIN loyalty_tiers ON loyalty_tiers.id = users.loyalty_tier_id")
          [ "loyalty_tiers.name", direction ]
        when 8
          [ "orders_count", direction ]
        when 9
          [ "total_order_amount_cents", direction ]
        when 10
          [ "users.status", direction ]
        else
          [ "users.id", "DESC" ]
        end

        if order_clause.present?
          if order_clause[0].is_a?(Array)
            # Handle multiple columns
            order_sql = order_clause[0].map { |col| "#{col} #{order_clause[1]}" }.join(", ")
            users = users.reorder(Arel.sql(order_sql))
          else
            users = users.reorder(Arel.sql("#{order_clause[0]} #{order_clause[1]}"))
          end
        end
      else
        users = users.order(id: :desc) # Default sorting
      end

      # Get the filtered count before pagination (create count query without GROUP BY)
      count_query = User.customers.joins(:customer)
      if params[:search][:value].present?
        search_term = "%#{params[:search][:value]}%"
        count_query = count_query.where("users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ? OR users.phone ILIKE ? OR customers.doc_id ILIKE ? OR customers.factura_ruc ILIKE ?", 
                                        search_term, search_term, search_term, search_term, search_term, search_term)
      end
      filtered_count = count_query.count
      
      # Pagination
      paginated_users = users.page(params[:start].to_i / params[:length].to_i + 1)
                            .per(params[:length].to_i)

      # Load price lists and loyalty tiers for the selected users
      price_lists = if $global_settings[:feature_flag_price_lists]
        PriceList.where(id: paginated_users.map(&:price_list_id).compact.uniq).index_by(&:id)
      else
        {}
      end
      
      loyalty_tiers = LoyaltyTier.where(id: paginated_users.map(&:loyalty_tier_id).compact.uniq).index_by(&:id)

      # Debug: let's see what the actual counts are
      total_customers = User.joins(:customer).where(internal: false).joins(:roles).where(roles: { name: 'customer' }).count
      Rails.logger.info "DEBUG: Total customers: #{total_customers}, Filtered: #{filtered_count}"
      
      {
        draw: params[:draw].to_i,
        recordsTotal: total_customers,
        recordsFiltered: filtered_count,
        data: paginated_users.map do |user|
          row = []

          # Use the data from the optimized query
          customer_name = user.name.blank? ? user.factura_razon_social : user.name
          doc_type = user.doc_id.blank? ? (user.factura_ruc.present? ? "ruc" : "dni") : user.doc_type
          doc_number = user.doc_id.blank? ? user.factura_ruc : user.doc_id

          row.concat([
            user.id,
            customer_name,
            user.email,
            user.phone,
            doc_type,
            doc_number
          ])

          if $global_settings[:feature_flag_price_lists]
            if user.price_list_id && price_lists[user.price_list_id]
              price_list_cell = %(<span class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-600/10 dark:bg-blue-900/20 dark:text-blue-400 dark:ring-blue-500/20">#{price_lists[user.price_list_id].name}</span>)
            else
              price_list_cell = %(<span class="text-gray-400 dark:text-gray-500">Predeterminada</span>)
            end
            row << price_list_cell
          end

          loyalty_tier_name = user.loyalty_tier_id ? loyalty_tiers[user.loyalty_tier_id]&.name : nil

          row.concat([
            loyalty_tier_name,
            user.orders_count,
            format_currency(user.total_order_amount),
            user.translated_status,
            render_actions(user)
          ])

          row
        end
      }
    end
    
    def render_actions(user)
      # For JSON responses, we need to use string literals instead of rendering partials
      pencil_icon = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10" /></svg>'
      trash_icon = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>'
      credit_card_icon = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z" /></svg>'
      
      actions = []
      
      # Skip for generic customer
      unless user.email == "generic_customer@devtechperu.com"
        # Edit link
        edit_link = link_to(
          pencil_icon.html_safe,
          edit_admin_customer_path(user),
          class: "inline-flex items-center rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 dark:bg-slate-700 dark:text-white dark:ring-slate-500 dark:hover:bg-slate-600",
          title: "Editar",
          data: { turbo_frame: "_top" }
        )
        actions << edit_link
        
        # Account Status link if feature flag is enabled
        if $global_settings[:pos_can_create_unpaid_orders]
          account_link = link_to(
            credit_card_icon.html_safe,
            admin_account_receivables_path(user_id: user.id),
            class: "inline-flex items-center rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 dark:bg-slate-700 dark:text-white dark:ring-slate-500 dark:hover:bg-slate-600",
            title: "Estado de Cuenta",
            data: { turbo_frame: "_top" }
          )
          actions << account_link
        end
        
        # Delete link if no orders (use orders_count from the query)
        if user.orders_count.to_i == 0
          delete_link = link_to(
            trash_icon.html_safe,
            admin_customer_path(user),
            class: "inline-flex items-center rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 dark:bg-slate-700 dark:text-white dark:ring-slate-500 dark:hover:bg-slate-600",
            title: "Eliminar",
            data: { turbo_method: :delete, turbo_confirm: "¿Estás seguro de eliminar este cliente?" }
          )
          actions << delete_link
        end
      end
      
      actions.join(" ").html_safe
    end
end
