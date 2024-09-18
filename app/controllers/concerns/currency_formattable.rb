module CurrencyFormattable
  extend ActiveSupport::Concern

  included do
    include ActionView::Helpers::NumberHelper
    include MoneyRails::ActionViewExtension
  end

  def format_currency(value, currency = Money.default_currency)
    if value.is_a?(Money)
      humanized_money_with_symbol(value)
    else
      number_to_currency(value,
        unit: currency.symbol,
        format: "%u %n",
        precision: 2,
        delimiter: ",",
        separator: "."
      )
    end
  end
end
