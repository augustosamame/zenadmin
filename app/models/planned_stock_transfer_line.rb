class PlannedStockTransferLine < ApplicationRecord
  belongs_to :planned_stock_transfer
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :fulfilled_quantity, numericality: { greater_than_or_equal_to: 0 }

  def fulfilled?
    fulfilled_quantity >= quantity
  end

  def partially_fulfilled?
    fulfilled_quantity > 0 && fulfilled_quantity < quantity
  end

  def pending_quantity
    [quantity - fulfilled_quantity, 0].max
  end
end
