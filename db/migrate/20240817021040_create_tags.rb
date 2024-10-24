class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name, null: false, index: { unique: true }
      t.integer :tag_type, default: 0
      t.boolean :visible_filter, default: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
