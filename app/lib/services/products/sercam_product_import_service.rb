require "csv"

module Services
  module Products
    class SercamProductImportService
      def initialize(file_path, max_rows = nil)
        @file_path = file_path
        @max_rows = max_rows
      end

      def import_individual_stock_transfer
        datetime_string = @file_path.split("st_").last
        datetime = datetime_string.to_datetime + 9.hours
        warehouse_main = Warehouse.find_by!(name: "Almacén Oficina Principal")
        user = User.find_by!(email: "almacen_principal@jardindelzen.com")

        location = Location.find_by!(name: @location_name)
        warehouse_location = location.warehouses.first
        brand = Brand.find_by!(name: "Jardín del Zen")
        ActiveRecord::Base.transaction do
          stock_transfer = StockTransfer.create!(user: user, origin_warehouse: warehouse_main, destination_warehouse: warehouse_location, transfer_date: datetime, status: :active, stage: :pending)
          CSV.foreach(@file_path, headers: true, liberal_parsing: true, encoding: "bom|utf-8", row_sep: :auto).with_index(1) do |row, index|
            product_name = row[2]
            quantity = row[3]&.to_i || 0

            found_product = Product.where("LOWER(name) = ?", product_name.downcase).first
            if found_product.blank?
              Rails.logger.info("Product #{product_name} not found. Creating it")
              found_product = Product.create!(name: product_name.downcase.capitalize, price_cents: 0, discounted_price_cents: 0, brand: brand, description: product_name.downcase.capitalize)
            end

            StockTransferLine.create!(stock_transfer: stock_transfer, product: found_product, quantity: quantity)
          end
          stock_transfer.finish_transfer!
        end
      end

      def fix_stocks_due_to_wrong_column
        # 11 is the wrong column for stock
        # 15 is the correct column for stock
        # we need to update the stock for the products in the file
        # we need to get the product name from column 5
        # we need to get the stock from column 15
        # we need to update the product with the new stock
        # we need to update the first stock transfer line with the new stock

        warehouse_main = Warehouse.find_by!(name: "Almacén Oficina Principal")
        user = User.find_by!(email: "almacen_principal@jardindelzen.com")

        location = Location.find_by!(name: @location_name)
        warehouse_location = location.warehouses.first
        brand = Brand.find_by!(name: "Jardín del Zen")

        if location.name == "Jockey"
          stock_transfer = StockTransfer.where(destination_warehouse: warehouse_location, origin_warehouse: warehouse_main).last
        else
          stock_transfer = StockTransfer.where(destination_warehouse: warehouse_location, origin_warehouse: warehouse_main).first
        end
        raise "First Stock transfer not found" if stock_transfer.blank?

        ActiveRecord::Base.transaction do
          CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
            product_name = row[5]
            correct_stock = row[16]&.to_i || 0
            incorrect_stock = row[11]&.to_i || 0
            delta = correct_stock - incorrect_stock

            # Find the product
            found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
            if found_product.blank?
              Rails.logger.info("Product #{product_name} not found. Creating it")
              found_product = Product.create!(
                name: product_name.downcase.capitalize,
                price_cents: 0,
                discounted_price_cents: 0,
                brand: brand,
                description: product_name.downcase.capitalize
              )
            end

            # Find the first stock transfer for this product
            # check that warehouse_inventory exists for this product
            warehouse_inventory = WarehouseInventory.find_by(warehouse: warehouse_location, product: found_product)
            if warehouse_inventory.blank?
              Rails.logger.info("Warehouse inventory not found for product #{product_name}. Creating it")
              warehouse_inventory = WarehouseInventory.create(warehouse: warehouse_location, product: found_product, stock: 0)
            end

            stock_transfer_line = stock_transfer.stock_transfer_lines
                                                .where(product: found_product)
                                                .order(created_at: :asc)
                                                .first

            if stock_transfer_line.blank?
              Rails.logger.info("No stock transfer line found for product #{product_name} (#{correct_stock} units). Creating it")
              stock_transfer_line = StockTransferLine.create!(
                stock_transfer: stock_transfer,
                product: found_product,
                quantity: correct_stock,
              ) unless correct_stock <= 0
            else

              Rails.logger.info("Updating stock for product #{product_name} from #{stock_transfer_line.quantity} to #{correct_stock}")

              # Update the stock transfer line
              stock_transfer_quantity = stock_transfer_line.quantity
              Rails.logger.info("New quantity in stock transfer line for product #{product_name}: #{stock_transfer_quantity + delta}")
              stock_transfer_line.update_columns(quantity: stock_transfer_quantity + delta, received_quantity: stock_transfer_quantity + delta)
            end

            # update stock in warehouse_inventory
            warehouse_inventory = WarehouseInventory.find_by(warehouse: warehouse_location, product: found_product)
            Rails.logger.info("No stock in warehouse inventory for product #{product_name}") if warehouse_inventory.blank?
            next if warehouse_inventory.blank?
            Rails.logger.info("Updating stock in warehouse inventory for product #{product_name}: #{warehouse_inventory.stock + delta}")
            warehouse_inventory.update_columns(stock: warehouse_inventory.stock + delta)
          end
        end

        puts "Stock correction completed"
      end

      def stocks_only
        brand = Brand.find_by!(name: "Jardín del Zen")
        warehouse = Warehouse.find_by!(name: "Almacén Oficina Principal")
        user = User.find_by!(email: "almacen_principal@jardindelzen.com")
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
            product_name = row[5]
            stock = row[11]&.to_i
            found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
            if found_product.blank?
              Rails.logger.info("Product #{product_name} not found. Creating it")
              found_product = Product.create!(
                name: product_name.downcase.capitalize,
                price_cents: 0,
                discounted_price_cents: 0,
                brand: brand,
                description: product_name.downcase.capitalize
              )
            end
            if stock.present? && stock > 0
              StockTransferLine.create!(
                stock_transfer: stock_transfer,
                product: found_product,
                quantity: stock,
              )
            end
          end
          stock_transfer.finish_transfer!

          puts "Stock transfer created with #{stock_transfer.stock_transfer_lines.count} lines"

          # transferencia inicial a tiendas
          location = Location.find_by!(name: @location_name)
          warehouse_location = location.warehouses.first
          ActiveRecord::Base.transaction do
            stock_transfer = StockTransfer.create!(
              user: user,
              origin_warehouse: warehouse, # es inventario inicial
              destination_warehouse: warehouse_location,
              transfer_date: Time.current,
              status: :active,
              stage: :pending,
            )
            CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
              product_name = row[5]
              stock = row[11]&.to_i
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

      def lookup_price(product_name)
        # Initialize the price cache if it doesn't exist
        @price_cache ||= load_price_cache

        # Look up the product name in the cache (case insensitive)
        # Return 0 if not found
        @price_cache[product_name.to_s.strip.downcase] || 0
      end

      # Load all prices from CSV into a hash for fast lookups
      def load_price_cache
        price_cache = {}

        # Check if the price file exists
        price_file = "sercam_product_prices.csv"
        unless File.exist?(price_file)
          Rails.logger.warn("Price file #{price_file} not found. All prices will be set to 0.")
          return price_cache
        end

        # Load the CSV file and build the cache
        Rails.logger.info("Loading prices from #{price_file}...")
        CSV.foreach(price_file, headers: true, encoding: "bom|utf-8", row_sep: :auto) do |row|
          # Skip if name is missing
          next if row[1].blank?

          # Column 1 is Name, Column 2 is Price
          product_name = row[1].to_s.strip.downcase
          price = row[2].to_i

          price_cache[product_name] = price
        end

        Rails.logger.info("Loaded #{price_cache.size} prices from #{price_file}")
        price_cache
      end

      def import_products_and_stocks
        # inventario inicial oficina principal
        ActiveRecord::Base.transaction do
          brand = Brand.first
          warehouse_talavera = Warehouse.find_by!(name: "Almacén Talavera")
          user_warehouse_talavera = User.find_by!(email: "talavera@sercamsrl.com")
          warehouse_eternit = Warehouse.find_by!(name: "Almacén Eternit")
          user_warehouse_eternit = User.find_by!(email: "eternit@sercamsrl.com")
          warehouse_agricultor = Warehouse.find_by!(name: "Almacén Agricultor")
          user_warehouse_agricultor = User.find_by!(email: "agricultor@sercamsrl.com")
          talavera_stock_transfer = StockTransfer.create!(
            user: user_warehouse_talavera,
            origin_warehouse: nil, # es inventario inicial
            destination_warehouse: warehouse_talavera,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )
          eternit_stock_transfer = StockTransfer.create!(
            user: user_warehouse_eternit,
            origin_warehouse: nil, # es inventario inicial
            destination_warehouse: warehouse_eternit,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )
          agricultor_stock_transfer = StockTransfer.create!(
            user: user_warehouse_agricultor,
            origin_warehouse: nil, # es inventario inicial
            destination_warehouse: warehouse_agricultor,
            transfer_date: Time.current,
            status: :active,
            stage: :pending,
          )

          CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
            break if index > (@max_rows || 100000)
            product_name = row[0]
            stock_talavera = row[1]&.to_i
            stock_agricultor = row[2]&.to_i
            stock_eternit = row[3]&.to_i
            next if stock_talavera.blank? && stock_eternit.blank? && stock_agricultor.blank?
            price = lookup_price(product_name)
            found_product = Product.find_by("UPPER(name) = ?", product_name.strip.upcase)
            found_product = Product.create!(
              name: product_name.strip.titleize,
              price_cents: price.to_f * 100,
              discounted_price_cents: price.to_f * 100,
              brand: brand,
              description: product_name.strip.titleize
            ) if found_product.nil?
            # stock
            if stock_talavera.present? && stock_talavera > 0
              StockTransferLine.create!(
                stock_transfer: talavera_stock_transfer,
                product: found_product,
                quantity: stock_talavera
              )
            end
            if stock_eternit.present? && stock_eternit > 0
              StockTransferLine.create!(
                stock_transfer: eternit_stock_transfer,
                product: found_product,
                quantity: stock_eternit
              )
            end
            if stock_agricultor.present? && stock_agricultor > 0
              StockTransferLine.create!(
                stock_transfer: agricultor_stock_transfer,
                product: found_product,
                quantity: stock_agricultor
              )
            end
          end
          talavera_stock_transfer.finish_transfer!
          eternit_stock_transfer.finish_transfer!
          agricultor_stock_transfer.finish_transfer!
        end
      end

      def create_missing_products
        CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
          product_name = row[2]
          found_product = Product.find_by("UPPER(name) = ?", product_name.upcase)
          if !found_product
            puts "Product #{product_name} not found"
            # Product.create!(name: product_name, price_cents: 0, discounted_price_cents: 0)
          end
        end
      end

      def main_warehouse_to_larcomar
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
            product_name = row[2]
            stock = row[3]&.to_i
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
            product_name = row[2]
            stock = row[3]&.to_i
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
