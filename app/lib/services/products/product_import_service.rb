require "csv"

module Services
  module Products
    class ProductImportService
      def initialize(file_path, max_rows = nil)
        @file_path = file_path
        @max_rows = max_rows
      end

      def call
        create_products_and_tags
      end

      private

      def create_products_and_tags
        CSV.foreach(@file_path, headers: true) do |row|
          product_name = row[0]
          tag_category_name = row[1]
          tag_sub_category_name = row[2]
          tag_volume_name = row[3]
          tag_weight_name = row[4]
          tag_fragance_name = row[5]
          tag_other_name = row[6]

          # random_tag_type = Tag.tag_types.keys.sample

          found_category_tag = Tag.find_by(name: tag_category_name)
          found_category_tag = Tag.create!(name: tag_category_name, tag_type: "category") if found_category_tag.blank? && tag_category_name.present?
          found_sub_category_tag = Tag.find_by(name: tag_sub_category_name)
          found_sub_category_tag = Tag.create!(name: tag_sub_category_name, tag_type: "sub_category", parent_tag: found_category_tag) if found_sub_category_tag.blank? && tag_sub_category_name.present?
          found_volume_tag = Tag.find_by(name: tag_volume_name)
          found_volume_tag = Tag.create!(name: tag_volume_name, tag_type: "capacity") if found_volume_tag.blank? && tag_volume_name.present?
          found_weight_tag = Tag.find_by(name: tag_weight_name)
          found_weight_tag = Tag.create!(name: tag_weight_name, tag_type: "weight") if found_weight_tag.blank? && tag_weight_name.present?
          found_fragance_tag = Tag.find_by(name: tag_fragance_name)
          found_fragance_tag = Tag.create!(name: tag_fragance_name, tag_type: "fragance") if found_fragance_tag.blank? && tag_fragance_name.present?
          found_other_tag = Tag.find_by(name: tag_other_name)
          found_other_tag = Tag.create!(name: tag_other_name, tag_type: "other") if found_other_tag.blank? && tag_other_name.present?

          product = Product.new(
            name: product_name.downcase.capitalize,
            description: "Description for #{product_name}",
            permalink: product_name.parameterize,
            price_cents: 4000,
            discounted_price_cents: 3500,
            # custom_id: custom_id,
            brand_id: 1
          )

          media = Media.new(
            file: URI.open(Faker::LoremFlickr.image(size: "300x300", search_terms: [ "product" ])),  # Replace with your S3 URL
            media_type: :default_image,  # Or any other media_type
            mediable: product
          )

          product.save!
          media.save!

          product.add_tag(found_category_tag) if found_category_tag.present?
          product.add_tag(found_sub_category_tag) if found_sub_category_tag.present?
          product.add_tag(found_volume_tag) if found_volume_tag.present?
          product.add_tag(found_weight_tag) if found_weight_tag.present?
          product.add_tag(found_fragance_tag) if found_fragance_tag.present?
          product.add_tag(found_other_tag) if found_other_tag.present?
        end
      end
    end
  end
end
