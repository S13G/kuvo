# frozen_string_literal: true

class ProductSize < ApplicationRecord
  has_many :product_variant
  has_many :products, through: :product_variant

  validates :name, :code, presence: true
  validates :code, uniqueness: true
end
