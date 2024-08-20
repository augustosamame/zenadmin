class Admin::MediaController < Admin::AdminController
  before_action :set_mediable

  def index
    @media = @mediable.media.ordered
  end

  def new
    @media = @mediable.media.new
  end

  def create
    @media = @mediable.media.new(media_params)
    if @media.save
      redirect_to admin_mediable_media_path(@mediable), notice: "Media was successfully uploaded."
    else
      render :new
    end
  end

  def edit
    @media = @mediable.media.find(params[:id])
  end

  def update
    @media = @mediable.media.find(params[:id])
    if @media.update(media_params)
      redirect_to admin_mediable_media_path(@mediable), notice: "Media was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @media = @mediable.media.find(params[:id])
    @media.destroy
    redirect_to admin_mediable_media_path(@mediable), notice: "Media was successfully deleted."
  end

  private

  def set_mediable
    @mediable = find_mediable
  end

  def find_mediable
    params.each do |name, value|
      if name =~ /(.+)_id$/
        return $1.classify.constantize.find(value)
      end
    end
    nil
  end

  def media_params
    params.require(:media).permit(:file_path, :media_type, :position)
  end
end
