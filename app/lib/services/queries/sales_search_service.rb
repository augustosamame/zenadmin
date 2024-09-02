class SalesSearchService
  def initialize(location: nil, seller: nil, date_range: nil)
    @location = location
    @seller = seller
    @date_range = date_range || (Time.now.beginning_of_month..Time.now.end_of_month) # Default to current month
  end
end
