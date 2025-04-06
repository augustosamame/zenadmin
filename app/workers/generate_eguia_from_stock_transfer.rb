class GenerateEguiaFromStockTransfer
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 1

  def perform(stock_transfer_id, options = {})
    sleep 1
    Rails.logger.info("Inside job: Generating guia for stock transfer #{stock_transfer_id}")
    puts "Inside job: Generating guia for stock transfer #{stock_transfer_id}"
    @options = options
    Services::Inventory::StockTransferGuiaService.new("stock_transfer", stock_transfer_id, @options).create_guia
  end
end
