class VoidEinvoice
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 1

  def perform(voided_order_id, options = {})
    sleep 1
    Rails.logger.info("Inside job: Voiding einvoice for voided order #{voided_order_id}")
    puts "Inside job: Voiding einvoice for voided order #{voided_order_id}"
    @voided_order = VoidedOrder.find(voided_order_id)
    @options = options
    Services::Sales::OrderInvoiceService.new(@voided_order, @options).void_invoice
  end
end
