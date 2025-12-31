# frozen_string_literal: true

class ProductSize < ApplicationRecord
  has_many :product_variants
  has_many :products, through: :product_variants

  validates :name, :code, presence: true
  validates :code, uniqueness: true

  def label
    "#{name} / #{code}"
  end
end
