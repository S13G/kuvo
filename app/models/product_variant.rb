# frozen_string_literal: true

class ProductVariant < ApplicationRecord
  belongs_to :product
  belongs_to :product_size, optional: true
  belongs_to :product_color, optional: true

  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: {
    scope: [:product_size_id, :product_color_id],
    message: "Variant already exists"
  }

  def label
    [product_size.name, product_color.hex_code].compact.join(" / ")
  end

  def in_stock?
    stock > 0
  end
end
