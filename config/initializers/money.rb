Money.locale_backend = :i18n

MoneyRails.configure do |config|
  config.default_currency = :pen
  config.rounding_mode = BigDecimal::ROUND_HALF_UP

  config.default_format = {
    format: "%u %n",
    symbol: "S/",
    thousands_separator: ",",
    decimal_mark: ".",
    sign_before_symbol: true
  }

  # Add this line to ensure Money objects use the currency specified in the model
  config.no_cents_if_whole = false
end
