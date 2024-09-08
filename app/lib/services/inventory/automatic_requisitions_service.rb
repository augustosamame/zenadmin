module Services
  module Inventory
    class AutomaticRequisitionsService
      def self.create_weekly_requisitions
        Location.active.each do |location|
          main_warehouse = Warehouse.main_warehouse # TODO: change to the specific warehouse assigned to supply the location
          user = User.where(location_id: location.id, internal: true).first # tienda user

          if main_warehouse && user
            Requisition.transaction do
              requisition = Requisition.new(
                requisition_date: Time.now,
                warehouse_id: main_warehouse.id,
                location_id: location.id,
                user_id: user.id,
                comments: "Pedido de reposición automático semanal para la ubicación #{location.name}"
              )

              Product.find_each do |product|
                requisition.requisition_lines.build(
                  product_id: product.id,
                  automatic_quantity: self.automatic_weekly_requisition_quantity(product, location),
                  presold_quantity: self.unrequisitioned_presold_quantity(product, location),
                  manual_quantity: 0,
                  supplied_quantity: 0,
                )
              end

              requisition.save!
            end
          end
        end
      end

      def self.automatic_weekly_requisition_quantity(product, location)
        # TODO: Implement the logic to calculate the automatic weekly requisition quantity
        # This is a placeholder method
        rand(1..10)
      end

      def self.unrequisitioned_presold_quantity(product, location)
        # TODO: Implement the logic to calculate the unrequisitioned presold quantity
        # This is a placeholder method
        rand(1..10)
      end
    end
  end
end
