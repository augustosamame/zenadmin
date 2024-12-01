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
                requisition_date: Time.current,
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
        # Look back 4 weeks (28 days) to calculate average weekly sales
        start_date = 4.weeks.ago.beginning_of_week
        end_date = Time.current.end_of_week

        # Get all order items for this product at this location within the date range
        total_quantity_sold = OrderItem
          .joins(:order)
          .where(
            product_id: product.id,
            orders: {
              location_id: location.id,
              created_at: start_date..end_date,
              status: :active # Only count completed orders
            }
          )
          .sum(:quantity)

        # Calculate weekly average (total sales divided by 4 weeks)
        weekly_average = (total_quantity_sold / 4.0).ceil

        # Get current stock
        warehouse = location.warehouses.first
        current_stock = product.stock(warehouse)

        # Get min/max stock settings for the product at the warehouse
        min_max_stock = ProductMinMaxStock.find_by(
          product_id: product.id,
          warehouse_id: warehouse.id
        )

        suggested_quantity = if min_max_stock && current_stock < min_max_stock.min_stock
          # If below minimum, suggest enough to reach max stock
          min_max_stock.max_stock - current_stock
        else
          # Otherwise suggest the weekly average
          weekly_average
        end

        [suggested_quantity, 0].max
      end

      def self.unrequisitioned_presold_quantity(product, location)
        # TODO: Implement the logic to calculate the unrequisitioned presold quantity
        # This is a placeholder method
        0
      end
    end
  end
end
