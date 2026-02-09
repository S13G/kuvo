class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def formatted_price(amount_cents)
    currency = begin
                 CurrencySetting.currency
               rescue StandardError
                 "USD"
               end
    Money.new(amount_cents || 0, currency || "USD").format
  end
end
