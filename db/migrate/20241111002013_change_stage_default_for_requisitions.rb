class ChangeStageDefaultForRequisitions < ActiveRecord::Migration[7.1]
  def up
    change_column_default :requisitions, :stage, from: 'req_pending', to: 'req_draft'
  end

  def down
    change_column_default :requisitions, :stage, from: 'req_draft', to: 'req_pending'
  end
end
