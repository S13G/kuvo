class ShippingFee < ApplicationRecord
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :singleton_guard, inclusion: { in: [true] }, uniqueness: true

  def self.instance
    first_or_create!(singleton_guard: true, amount_cents: 5000)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[amount_cents id singleton_guard created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
