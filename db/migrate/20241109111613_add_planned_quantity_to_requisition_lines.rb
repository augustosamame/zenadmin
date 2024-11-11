class AddPlannedQuantityToRequisitionLines < ActiveRecord::Migration[7.2]
  def change
    add_column :requisition_lines, :planned_quantity, :integer
  end
end
