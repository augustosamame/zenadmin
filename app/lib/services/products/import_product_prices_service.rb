require "csv"

module Services
  module Products
    class ImportProductPricesService
      def initialize(file_path, max_rows = nil)
        @file_path = file_path
        @max_rows = max_rows
      end

      def call
        apply_prices_to_products
      end

      private

      def apply_prices_to_products
        CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
          break if @max_rows && index > @max_rows
          product_name = row[5]
          price = row[18]

          product = Product.find_by("LOWER(name) = ?", product_name.downcase)

          if product.present?
            puts "Updating product #{product_name} with price #{price}"
            product.update!(price_cents: price.to_f * 100, discounted_price_cents: price.to_f * 100)
          else
            puts "Product #{product_name} not found"
          end
        end
      end

      # def generate_custom_id(product_category_name, index)
      #  category_code = product_category_name[0, 3].upcase
      #  id_code = index.to_s.rjust(5, "0")
      #  "#{category_code}#{id_code}"
      # end
    end
  end
end
