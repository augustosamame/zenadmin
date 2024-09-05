class GenerateEinvoice
  include Sidekiq::Worker

  def perform(order_id, options = {})
    @order = Order.find(order_id)
    @options = options
    Services::Sales::OrderInvoiceService.new(@order, @options).create_invoices
  end
end
