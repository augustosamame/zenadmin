class RequisitionLine < ApplicationRecord
  belongs_to :requisition
  belongs_to :product

  validates :product_id, presence: true
  validates :automatic_quantity, :manual_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :presold_quantity, :supplied_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :manual_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :status, { pending: 0, fulfilled: 1 }

  attr_accessor :current_stock

  before_validation :set_automatic_and_presold_quantities_if_blank

  def set_automatic_and_presold_quantities_if_blank
    self.automatic_quantity ||= 0
    self.presold_quantity ||= 0
  end
end
