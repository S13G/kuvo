# frozen_string_literal: true

class Discount < ApplicationRecord
  validates :percentage_off, inclusion: { in: 1..100 }
  validate :only_one_discount, on: :create
  validates :singleton_guard, uniqueness: true

  def active?
    active && (starts_at < Time.current && ends_at > Time.current)
  end

  private

  def only_one_discount
    if Discount.exists?
      errors.add(:base, "A discount already exists. Only one discount can exist at a time.")
    end
  end
end
