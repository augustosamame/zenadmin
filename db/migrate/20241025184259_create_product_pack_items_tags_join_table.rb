class CreateProductPackItemsTagsJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_join_table :product_pack_items, :tags do |t|
      t.index [:product_pack_item_id, :tag_id], name: 'index_pp_items_tags_on_pp_item_id_and_tag_id'
      t.index [:tag_id, :product_pack_item_id], name: 'index_pp_items_tags_on_tag_id_and_pp_item_id'
    end
  end
end