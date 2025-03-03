class AddOriginalPaymentIdToPayments < ActiveRecord::Migration[7.2]
  def change
    add_reference :payments, :original_payment, foreign_key: { to_table: :payments }
  end
end
