class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :product_variant, optional: true

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(auth_object = nil)
    %w[id created_at updated_at tracking_number]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order product product_variant]
  end

  def item_unit_price_cents
    product.discounted_price_cents.presence || product.price_cents
  end

  def item_total_price_cents
    item_unit_price_cents * quantity
  end

  def as_json(options = nil)
    {
      id: id,
      quantity: quantity,
      item_unit_price_cents: item_unit_price_cents,
      item_total_price_cents: item_total_price_cents,
      product: {
        product_id: product_id,
        product_name: product.name,
        product_variant_id: product_variant_id,
        size: product_variant&.product_size&.name,
        color: product_variant&.product_color&.name,
        stock: product_variant.stock
      }
    }
  end
end
