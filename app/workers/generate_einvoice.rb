class GenerateEinvoice
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 1

  def perform(order_id, options = {})
    Rails.logger.info("Inside job: Generating einvoice for order #{order_id}")
    puts "Inside job: Generating einvoice for order #{order_id}"
    @order = Order.find(order_id)
    @options = options
    Services::Sales::OrderInvoiceService.new(@order, @options).create_invoices
  end
end
