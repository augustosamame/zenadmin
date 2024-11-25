module Admin::AccountReceivablesHelper
  def status_badge_class(status)
    base_classes = "px-2 py-1 text-xs font-medium rounded-full"

    status_classes = {
      "pending" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
      "partially_paid" => "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
      "paid" => "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
      "cancelled" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
    }

    "#{base_classes} #{status_classes[status]}"
  end
end
