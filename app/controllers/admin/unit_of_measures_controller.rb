class Admin::UnitOfMeasuresController < Admin::AdminController
  before_action :set_unit_of_measure, only: [ :edit, :update, :destroy ]

  def index
    authorize! :read, UnitOfMeasure
    @datatable_options = "resource_name:'UnitOfMeasure';sort_0_asc;create_button:true;"
    @unit_of_measures = UnitOfMeasure.includes([ :reference_unit ]).order(:name)
    respond_to do |format|
      format.html
      format.json { render json: @unit_of_measures }
    end
  end

  def new
    authorize! :create, UnitOfMeasure
    @unit_of_measure = UnitOfMeasure.new
  end

  def create
    authorize! :create, UnitOfMeasure
    @unit_of_measure = UnitOfMeasure.new(unit_of_measure_params)
    if @unit_of_measure.save
      redirect_to admin_unit_of_measures_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @unit_of_measure
  end

  def update
    authorize! :update, @unit_of_measure
    if @unit_of_measure.update(unit_of_measure_params)
      redirect_to admin_unit_of_measures_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @unit_of_measure
    @unit_of_measure.destroy
    redirect_to admin_unit_of_measures_path, notice: t(".destroyed")
  end

  private
    def set_unit_of_measure
      @unit_of_measure = UnitOfMeasure.find(params[:id])
    end

    def unit_of_measure_params
      params.require(:unit_of_measure).permit(:name, :abbreviation, :reference_unit_id, :multiplier, :status, :default, :notes)
    end
end
