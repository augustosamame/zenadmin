module ApplicationHelper
  def format_currency(value, currency = Money.default_currency)
    if value.is_a?(Money)
      humanized_money_with_symbol(value)
    else
      if value.present?
        formatted_value = number_to_currency(value,
          unit: currency.symbol,
        format: "%u %n",
        precision: 2,
        delimiter: ",",
          separator: "."
        )
        formatted_value.gsub(/^(\D+)/, '\1 ').gsub(/\s+/, " ")
      else
        ""
      end
    end
  end
end
