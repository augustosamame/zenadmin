class AddAccessFieldToCashier < ActiveRecord::Migration[8.0]
  def change
    add_column :cashiers, :access, :string, null: false, default: "all"
    add_column :payment_methods, :access, :string, null: false, default: "all"
  end
end
