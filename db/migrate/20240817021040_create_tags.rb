class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.references :parent_tag, foreign_key: { to_table: :tags }, null: true
      t.string :name, null: false, index: { unique: true }
      t.integer :tag_type, default: 0
      t.boolean :visible_filter, default: false
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :tags, :tag_type
    add_index :tags, :status
    add_index :tags, :visible_filter
  end
end
