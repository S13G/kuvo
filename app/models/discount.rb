# frozen_string_literal: true

class Discount < ApplicationRecord
  validates :percentage_off, inclusion: { in: 1..100 }

  before_save :ensure_single_active_discount

  scope :active, -> {
    where(active: true)
      .where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current)
  }

  private

  def ensure_single_active_discount
    if active? == false
      return
    end

    Discount.where(active: true).where.not(id: id).update_all(active: false)
  end
end
