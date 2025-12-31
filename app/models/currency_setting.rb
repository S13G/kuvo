# frozen_string_literal: true

class CurrencySetting < ApplicationRecord
  validate :only_one_currency_setting, on: :create
  validates :singleton_guard, uniqueness: true

  def self.currency
    first_or_create.currency
  end

  def to_s
    currency
  end

  private

  def only_one_currency_setting
    if CurrencySetting.exists?
      errors.add(:base, "A currency setting already exists. Only one currency setting can exist at a time.")
    end
  end
end
