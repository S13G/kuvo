class ShippingFee < ApplicationRecord
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :singleton_guard, inclusion: { in: [true] }, uniqueness: true

  def self.instance
    first_or_create!(singleton_guard: true, amount_cents: 500)
  end
end
