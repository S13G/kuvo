# frozen_string_literal: true

class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :product_variant, optional: true

  validates :quantity, numericality: { greater_than: 0 }

  def item_unit_price_cents
    product.discounted_price_cents.presence || product.price_cents
  end

  def item_total_price_cents
    item_unit_price_cents * quantity
  end

  def as_json(_options = nil)
    {
      id: id,
      product: {
        id: product_id,
        name: product.name,
        product_variant_id: product_variant_id,
        stock: product_variant.stock
      },
      quantity: quantity,
      item_unit_price_cents: item_unit_price_cents,
      item_total_price_cents: item_total_price_cents
    }
  end
end
