class CreateMedia < ActiveRecord::Migration[7.2]
  def change
    create_table :media do |t|
      t.string :file_path, null: false
      t.integer :media_type, default: 0
      t.references :mediable, polymorphic: true, null: false
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
