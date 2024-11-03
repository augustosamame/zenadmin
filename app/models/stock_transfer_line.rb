class StockTransferLine < ApplicationRecord
  belongs_to :stock_transfer
  belongs_to :product

  delegate :is_adjustment?, to: :stock_transfer

  validates :quantity, numericality: { greater_than: 0 }, unless: :is_adjustment?
  before_save :set_received_quantity

  private

  def set_received_quantity
    self.received_quantity = quantity if received_quantity.blank?
  end
end
