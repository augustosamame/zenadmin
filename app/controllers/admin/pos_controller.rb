class Admin::PosController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

	def new
    @order = Order.new
  end

end
