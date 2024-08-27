class WarehouseInventory < ApplicationRecord
  audited_if_enabled

  belongs_to :warehouse
  belongs_to :product

  validate :stock_numericality_based_on_settings
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "should have a unique product stock record" }

  private

    def stock_numericality_based_on_settings
      unless $global_settings[:negative_stocks_allowed]
        errors.add(:stock, "El stock resultante debe ser igual o mayor que 0") if stock < 0
      end
    end
end
