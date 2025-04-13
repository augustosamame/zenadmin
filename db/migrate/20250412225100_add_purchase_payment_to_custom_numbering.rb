class AddPurchasePaymentToCustomNumbering < ActiveRecord::Migration[8.0]
  def up
    # Create the custom numbering for purchase_payment if it doesn't exist
    unless CustomNumbering.exists?(record_type: 13)
      CustomNumbering.create!(
        record_type: 13, # purchase_payment
        prefix: "PPR",
        length: 6,
        next_number: 1,
        status: 0 # active
      )
    end
  end

  def down
    CustomNumbering.where(record_type: 13).destroy_all
  end
end
