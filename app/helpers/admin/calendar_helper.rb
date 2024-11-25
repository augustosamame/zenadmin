module Admin::CalendarHelper
  def payment_status_class(status)
    case status
    when "pending"
      "bg-yellow-500 border-yellow-600"
    when "overdue"
      "bg-red-500 border-red-600"
    when "paid"
      "bg-green-500 border-green-600"
    else
      "bg-gray-500 border-gray-600"
    end
  end
end
