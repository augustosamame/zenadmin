require "csv"

module Services
  module Products
    class ProductImportService
      def initialize(file_path, max_rows = nil)
        @file_path = file_path
        @max_rows = max_rows
      end

      def call
        create_product_categories_and_tags_and_products
      end

      private

      def create_product_categories_and_tags_and_products
        CSV.foreach(@file_path, headers: true) do |row|
          product_category_name = row[0]
          tag1_name = row[2]
          tag2_name = row[3]

          ProductCategory.find_or_create_by!(name: product_category_name)
          Tag.find_or_create_by!(name: tag1_name) if tag1_name.present?
          Tag.find_or_create_by!(name: tag2_name) if tag2_name.present?
        end

        CSV.foreach(@file_path, headers: true).with_index(1) do |row, index|
          break if @max_rows && index > @max_rows
          product_category_name = row[0]
          product_name = row[1]
          tag1_name = row[2]
          tag2_name = row[3]
          brand_id = row[4]

          product_category = ProductCategory.find_by(name: product_category_name)
          # custom_id = generate_custom_id(product_category_name, index)

          product = Product.new(
            name: product_name.downcase.capitalize,
            description: "Description for #{product_name}",
            permalink: product_name.parameterize,
            price_cents: 4000,
            discounted_price_cents: 3500,
            # custom_id: custom_id,
            brand_id: brand_id,
            product_categories: [ product_category ]
          )

          media = Media.new(
            file: URI.open(Faker::LoremFlickr.image(size: "300x300", search_terms: [ "product" ])),  # Replace with your S3 URL
            media_type: :default_image,  # Or any other media_type
            mediable: product
          )

          # Save both product and media together
          product.save!
          media.save!

          product.add_tag(tag1_name) if tag1_name.present?
          product.add_tag(tag2_name) if tag2_name.present?
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
