require "csv"

module Services
  module Products
    class InitialStockImportService
      def initialize(file_path, max_rows = nil)
        @file_path = file_path
        @max_rows = max_rows
      end

      def stock_and_prices
        warehouse = Warehouse.find_by!(name: "Almacén Oficina Principal")
        user = User.find_by!(email: "almacen_principal@jardindelzen.com")
        # inventario inicial oficina principal
        ActiveRecord::Base.transaction do
          stock_transfer = StockTransfer.create!(
            user: user,
            origin_warehouse: nil, # es inventario inicial
            destination_warehouse: warehouse,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )
          CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
            product_name = row[1]
            stock = row[8]&.to_i
            price = row[9]
            found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
            # stock
            if found_product && stock.present? && stock > 0
              StockTransferLine.create!(
                stock_transfer: stock_transfer,
                product: found_product,
                quantity: stock,
              )
            end
            # price
            if found_product
              Rails.logger.info("Updating product #{product_name} with price #{price}")
              found_product.update!(price_cents: price.to_f * 100, discounted_price_cents: price.to_f * 100)
            else
              Rails.logger.info("Product #{product_name} not found")
            end
          end
          stock_transfer.finish_transfer!
        end
        # transferencia inicial a tiendas
        warehouse_1 = Warehouse.find_by!(name: "Almacén Larcomar")
        ActiveRecord::Base.transaction do
          stock_transfer = StockTransfer.create!(
            user: user,
            origin_warehouse: warehouse, # es inventario inicial
            destination_warehouse: warehouse_1,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )
          CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
            product_name = row[1]
            stock = row[8]&.to_i
            found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
            if found_product && stock.present? && stock > 0
              StockTransferLine.create!(
                stock_transfer: stock_transfer,
                product: found_product,
                quantity: stock,
              )
            end
          end
          stock_transfer.finish_transfer!
        end
        # set price to zero for products with stock 0 in warehouse 1 and price 40
        Product.where(price_cents: 4000).update_all(price_cents: 0, discounted_price_cents: 0)
      end

      def call
        warehouse = Warehouse.find_by!(name: "Almacén Oficina Principal")
        user = User.find_by!(email: "almacen_principal@jardindelzen.com")
        # inventario inicial oficina principal
        ActiveRecord::Base.transaction do
          stock_transfer = StockTransfer.create!(
            user: user,
            origin_warehouse: nil, # es inventario inicial
            destination_warehouse: warehouse,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )
          CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
            product_name = row[1]
            stock = row[4]&.to_i
            found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
            if found_product && stock.present? && stock > 0
              StockTransferLine.create!(
                stock_transfer: stock_transfer,
                product: found_product,
                quantity: stock,
              )
            end
          end
          stock_transfer.finish_transfer!
        end
        # transferencia inicial a tiendas
        warehouse_1 = Warehouse.find_by!(name: "Almacén Plaza Norte")
        ActiveRecord::Base.transaction do
          stock_transfer = StockTransfer.create!(
            user: user,
            origin_warehouse: warehouse, # es inventario inicial
            destination_warehouse: warehouse_1,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )
          CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
            product_name = row[1]
            stock = row[4]&.to_i
            found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
            if found_product && stock.present? && stock > 0
              StockTransferLine.create!(
                stock_transfer: stock_transfer,
                product: found_product,
                quantity: stock,
              )
            end
          end
          stock_transfer.finish_transfer!
        end
      end
    end
  end
end
