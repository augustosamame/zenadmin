class RequisitionLine < ApplicationRecord
  belongs_to :requisition
  belongs_to :product

  validates :automatic_quantity, :manual_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :presold_quantity, :supplied_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :status, { pending: 0, fulfilled: 1 }

  before_validation :set_automatic_and_presold_quantities_if_blank

  def set_automatic_and_presold_quantities_if_blank
    self.automatic_quantity ||= 0
    self.presold_quantity ||= 0
  end
end
