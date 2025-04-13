class PurchaseInvoicePayment < ApplicationRecord
  audited_if_enabled
  
  belongs_to :purchase_invoice
  belongs_to :purchase_payment
  
  monetize :amount_cents, with_model_currency: :currency
  
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :purchase_invoice_id, :purchase_payment_id, presence: true
  
  after_create :update_purchase_invoice_status
  after_destroy :update_purchase_invoice_status
  
  private
  
  def update_purchase_invoice_status
    purchase_invoice.reload
    total_paid = purchase_invoice.purchase_invoice_payments.sum(:amount_cents)
    
    if total_paid <= 0
      purchase_invoice.update(payment_status: :pending)
    elsif total_paid < purchase_invoice.amount_cents
      purchase_invoice.update(payment_status: :partially_paid)
    else
      purchase_invoice.update(payment_status: :paid)
    end
  end
end
