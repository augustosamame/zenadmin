class Admin::GuiasController < Admin::AdminController
  before_action :set_guia, only: [ :show ]

  def index
    respond_to do |format|
      format.html do
        @guias = Guia.includes(:stock_transfer, :order, :guia_series).order(id: :desc)
        @datatable_options = "server_side:true;resource_name:'Guia'; sort_0_desc;hide_0;create_button:false"
        @default_object_options_array = [
          { event_name: "show", label: "Ver", icon: "eye" }
        ]
      end
      format.json do
        render json: datatable_json
      end
    end
  end

  def show
  end

  def datatable_json
    guias = Guia.includes(:stock_transfer, :order, :guia_series).order(id: :desc)
    {
      data: guias.map do |guia|
        guia_url_html =
          if guia.sunat_status == "sunat_error"
            # Always show Retry if sunat_error; only show link if guia_url present
            (guia.guia_url.present? ? view_context.link_to("Ver Guía", guia.guia_url, target: "_blank", class: "text-blue-600 hover:underline mr-2") : "") +
            view_context.button_to("Reenviar", view_context.admin_generate_guia_path, method: :post, params: { source_type: "guia", source_id: guia.id }, class: "btn btn-xs btn-primary", data: { turbo: false })
          elsif guia.guia_url.present?
            # Normal case: show link only
            view_context.link_to("Ver Guía", guia.guia_url, target: "_blank", class: "text-blue-600 hover:underline")
          else
            # Not sunat_error but no guia_url: show Retry
            view_context.button_to("Reenviar", view_context.admin_generate_guia_path, method: :post, params: { source_type: "guia", source_id: guia.id }, class: "btn btn-xs btn-primary", data: { turbo: false })
          end
        [
          guia.created_at.strftime("%Y-%m-%d %H:%M"),
          guia.custom_id,
          guia.translated_guia_type,
          guia.translated_status,
          guia.translated_sunat_status,
          guia.stock_transfer&.custom_id,
          guia.order&.custom_id,
          guia_url_html,
          view_context.link_to("Ver Detalles", admin_guia_path(guia), class: "text-blue-600 hover:underline")
        ]
      end
    }
  end

  private

  def set_guia
    @guia = Guia.find(params[:id])
  end
end
