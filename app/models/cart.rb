# frozen_string_literal: true

class Cart < ApplicationRecord
  class CartError < StandardError; end

  belongs_to :user
  has_many :cart_items, dependent: :destroy

  enum :payment_status, {
    pending: "pending",
    paid: "paid",
    cancelled: "cancelled"
  }

  validates :user, presence: true

  def add_item!(product_id:, product_variant_id:, quantity:)
    quantity = quantity.to_i
    if quantity <= 0
      raise CartError, "Invalid quantity"
    end

    product = Product.find_by(id: product_id)
    if product.nil?
      raise CartError, "Product not found"
    end

    variant = resolve_variant(product, product_variant_id, quantity)

    cart_item = cart_items.find_or_initialize_by(
      product: product,
      product_variant: variant
    )

    cart_item.quantity += quantity
    cart_item.save!
  end

  def remove_item!(cart_item_id:, quantity:)
    cart_item = cart_items.find_by(id: cart_item_id)
    if cart_item.nil?
      raise CartError, "Cart item not found"
    end

    quantity = quantity.to_i

    if quantity > 0 && cart_item.quantity > quantity
      cart_item.update!(quantity: cart_item.quantity - quantity)
    else
      cart_item.destroy!
    end
  end

  def total_cart_amount_in_cents
    cart_items.sum(&:item_total_price_cents)
  end

  def as_json(_options = nil)
    {
      id: id,
      payment_status: payment_status,
      total_cart_amount_in_cents: total_cart_amount_in_cents,
      cart_items: cart_items.as_json
    }
  end

  private

  def resolve_variant(product, variant_id, quantity)
    if variant_id.present?
      variant = product.product_variants.find_by(id: variant_id)

      if variant.nil?
        raise CartError, "Variant not found" unless variant
      end

      if variant.stock < quantity
        raise CartError, "Variant out of stock"
      end

      variant
    else
      if product.stock < quantity
        raise CartError, "Product out of stock"
      end

      nil
    end
  end
end
