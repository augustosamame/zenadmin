module CurrencyFormattable
  extend ActiveSupport::Concern

  included do
    include ActionView::Helpers::NumberHelper
    include MoneyRails::ActionViewExtension
  end

  def format_currency(value, currency = Money.default_currency)
    if value.is_a?(Money)
      humanized_money_with_symbol(value)
    elsif value.is_a?(String)
      humanized_money_with_symbol(Money.new(value.to_f, currency))
    else
      rounded_value = value.to_f.round(2)
      number_to_currency(rounded_value,
        unit: currency.symbol,
        format: "%u %n",
        precision: 2,
        delimiter: ",",
        separator: "."
      )
    end
  end
end
