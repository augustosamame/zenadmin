class Admin::CustomersController < Admin::AdminController
  def index
    customers = User.with_role("customer")
    render json: customers.select(:id, :first_name, :last_name, :email, :phone)
  end

  def search_dni
    response = Services::ReniecSunat::ConsultaDniRucPerudevs.consultar_dni(params[:numero])
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
