class Admin::TagsController < Admin::AdminController
  before_action :set_tag, only: [ :edit, :update, :destroy ]

  def index
    @tags = Tag.includes(:parent_tag).order(created_at: :desc)
    @datatable_options = "resource_name:'Tag';create_button:true;hide_0;sort_0_asc;"
  end

  def new
    @tag = Tag.new
  end

  def edit
  end

  def create
    @tag = Tag.new(tag_params)
    if @tag.save
      redirect_to admin_tags_path, notice: "La etiqueta fue creada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @tag.update(tag_params)
      redirect_to admin_tags_path, notice: "La etiqueta fue actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy
    redirect_to admin_tags_path, notice: "La etiqueta fue eliminada exitosamente."
  end

  private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :tag_type, :visible_filter, :parent_tag_id, :status)
    end
end
