class Admin::ProductsController < ApplicationController
	layout "admin"

	def index
    @products = Product.all
    @object_options_array = [
      { event_name: "edit", label: "Editar", icon: "pencil-square" },
      { event_name: "delete", label: "Eliminar", icon: "trash" },
    ]
	end

end
