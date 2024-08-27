class StockTransferLine < ApplicationRecord
  belongs_to :stock_transfer
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
end
