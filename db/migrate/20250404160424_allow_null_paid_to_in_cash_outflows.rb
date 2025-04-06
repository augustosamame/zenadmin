class AllowNullPaidToInCashOutflows < ActiveRecord::Migration[8.0]
  def change
    # Change the paid_to_id column to allow null values
    change_column_null :cash_outflows, :paid_to_id, true
  end
end
