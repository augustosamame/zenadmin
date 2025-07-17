class AddIndexesForCustomerPerformance < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for user_roles table to optimize role lookups
    add_index :user_roles, [:user_id, :role_id], unique: true, name: 'index_user_roles_on_user_id_and_role_id' unless index_exists?(:user_roles, [:user_id, :role_id])
    
    # Add index on users.internal for filtering internal users
    add_index :users, :internal, name: 'index_users_on_internal' unless index_exists?(:users, :internal)
    
    # Add composite index for customers on user_id and price_list_id
    add_index :customers, [:user_id, :price_list_id], name: 'index_customers_on_user_id_and_price_list_id' unless index_exists?(:customers, [:user_id, :price_list_id])
    
    # Add index for customers doc_id searches
    add_index :customers, :doc_id, name: 'index_customers_on_doc_id' unless index_exists?(:customers, :doc_id)
    
    # Add index for customers factura_ruc searches
    add_index :customers, :factura_ruc, name: 'index_customers_on_factura_ruc' unless index_exists?(:customers, :factura_ruc)
    
    # Add composite index for orders on user_id and status for counting
    add_index :orders, [:user_id, :status], name: 'index_orders_on_user_id_and_status' unless index_exists?(:orders, [:user_id, :status])
  end
end
