# frozen_string_literal: true

class Cart < ApplicationRecord
  class CartError < StandardError; end

  belongs_to :user, dependent: :destroy
  has_many :cart_items, dependent: :destroy

  validates :user, presence: true

  def add_item!(product_id:, product_variant_id:, quantity:)
    quantity = quantity.to_i

    product = Product.find_by(id: product_id)
    if product.nil?
      raise CartError, "Product not found"
    end

    if product.product_variants.any? && product_variant_id.blank?
      raise CartError, "Variant is required for this product"
    end

    if product.total_stock < quantity
      raise CartError, "Product out of stock"
    end

    if product_variant_id.present?
      variant = resolve_variant(product, product_variant_id, quantity)
    end

    cart_item = cart_items.find_or_initialize_by(
      product: product,
      product_variant: variant || nil,
      quantity: quantity
    )

    cart_item.save!
  end

  def change_item_quantity!(cart_item_id:, quantity:)
    cart_item = cart_items.find_by(id: cart_item_id)
    raise CartError, "Cart item not found" if cart_item.nil?

    quantity = quantity.to_i
    if quantity > 0
      cart_item.update!(quantity: quantity)
    else
      raise CartError, "Quantity must be greater than 0"
    end
  end

  def remove_item!(cart_item_id:)
    cart_item = cart_items.find_by(id: cart_item_id)
    raise CartError, "Cart item not found" if cart_item.nil?

    cart_item.destroy!
  end

  def total_cart_amount_in_cents
    cart_items.sum(&:item_total_price_cents)
  end

  def as_json(_options = nil)
    {
      id: id,
      total_cart_amount_in_cents: total_cart_amount_in_cents,
      cart_items: cart_items.as_json
    }
  end

  private

  def resolve_variant(product, variant_id, quantity)
    variant = product.product_variants.find_by(id: variant_id)

    if variant.nil?
      raise CartError, "Variant not found"
    end

    if variant.stock < quantity
      raise CartError, "Variant out of stock"
    end

    variant
  end
end
