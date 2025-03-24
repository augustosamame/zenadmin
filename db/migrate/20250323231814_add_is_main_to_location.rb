class AddIsMainToLocation < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :is_main, :boolean, default: false
  end
end
