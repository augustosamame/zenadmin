class CreateUserFreeProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :user_free_products do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :loyalty_tier, null: false, foreign_key: true
      t.datetime :received_at
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
