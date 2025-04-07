class Admin::TransportistasController < Admin::AdminController
  before_action :set_transportista, only: [:show, :edit, :update, :destroy]

  def index
    authorize! :read, Transportista
    @transportistas = Transportista.all.order(id: :asc)
    @datatable_options = "resource_name:'Transportista';create_button:true;sort_0_desc;"
    
    @default_object_options_array = [
      { event_name: 'edit', label: 'Editar', icon: 'pencil-square' },
      { event_name: 'delete', label: 'Eliminar', icon: 'trash' }
    ]

    respond_to do |format|
      format.html
      format.json {
        render json: {
          data: @transportistas.map do |transportista|
            [
              transportista.transportista_type.titleize,
              transportista.ruc? ? transportista.razon_social : "#{transportista.first_name} #{transportista.last_name}",
              transportista.ruc? ? "RUC: #{transportista.ruc_number}" : "DNI: #{transportista.dni_number}",
              transportista.vehicle_plate,
              "<span class='inline-flex rounded-full px-2 text-xs font-semibold leading-5 #{transportista.active? ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}'>#{transportista.status.titleize}</span>",
              "<div data-controller='dropdown' class='relative'>
                <button data-action='click->dropdown#toggle click@window->dropdown#hide' class='p-2 rounded-lg focus:ring-4 focus:ring-primary-50 dark:focus:ring-slate-600/50'>
                  #{helpers.icon('cog-6-tooth', classes: 'w-6 h-6 stroke-current text-slate-500 group-hover:text-primary-600 dark:group-hover:text-primary-400')}
                </button>
                <ul data-dropdown-target='menu' class='hidden absolute right-0 top-10 bg-white rounded-lg shadow-xl dark:bg-slate-700 dark:shadow-slate-900/50 dark:border-slate-500/60 w-[200px] z-50 py-2'>
                  #{@default_object_options_array.map { |option| 
                    "<li>
                      <a href='#' data-action='click->dropdown#handleAction' data-object-id='#{transportista.id}' data-event-name='#{option[:event_name]}' class='px-4 py-[.4rem] group flex items-center justify-start space-x-3'>
                        #{helpers.icon(option[:icon], classes: 'stroke-current w-5 h-5 text-slate-500 group-hover:text-primary-600 dark:group-hover:text-primary-400')}
                        <span>#{option[:label]}</span>
                      </a>
                    </li>"
                  }.join}
                </ul>
              </div>"
            ]
          end
        }
      }
    end
  end

  def show
    authorize! :read, @transportista
  end

  def new
    authorize! :create, Transportista
    @transportista = Transportista.new
  end

  def create
    @transportista = Transportista.new(transportista_params)
    if @transportista.save
      redirect_to admin_transportistas_path, notice: "Transportista fue creado exitosamente."
    else
      render :new
    end
  end

  def edit
    authorize! :update, @transportista
  end

  def update
    if @transportista.update(transportista_params)
      redirect_to admin_transportistas_path, notice: "Transportista fue actualizado exitosamente."
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @transportista
    @transportista.destroy
    redirect_to admin_transportistas_path, notice: "Transportista fue eliminado exitosamente."
  end

  private

  def set_transportista
    @transportista = Transportista.find(params[:id])
  end

  def transportista_params
    params.require(:transportista).permit(
      :transportista_type, 
      :doc_type, 
      :first_name, 
      :last_name, 
      :license_number, 
      :dni_number, 
      :razon_social, 
      :ruc_number, 
      :vehicle_plate, 
      :numero_mtc, 
      :m1l_indicator, 
      :transportista_order, 
      :status
    )
  end
end
