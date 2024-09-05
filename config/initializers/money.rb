# encoding : utf-8

MoneyRails.configure do |config|
  # To set the default currency
  #
  config.default_currency = :pen

  Money.locale_backend = :i18n
  #
  config.rounding_mode = BigDecimal::ROUND_HALF_UP

end
