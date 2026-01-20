# frozen_string_literal: true

class ProductVariant < ApplicationRecord
  belongs_to :product
  belongs_to :product_size, optional: true
  belongs_to :product_color, optional: true

  attr_accessor :size_name, :size_code, :color_name, :color_hex

  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: {
    scope: [:product_size_id, :product_color_id],
    message: "Variant already exists"
  }

  before_validation :resolve_size_and_color
  after_commit :sync_product_activity

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id product_id product_size_id product_color_id stock updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[product product_size product_color]
  end

  def to_s
    [
      product_size&.name,
      product_color&.name
    ].compact.join(" / ")
  end

  def update_stock(quantity)
    with_lock do
      self.stock -= quantity
      save!
    end
  end

  def as_json(options = nil)
    {
      id: id,
      stock: stock,
      size_name: product_size&.name,
      size_code: product_size&.code,
      color_name: product_color&.name,
      color_hex: product_color&.hex_code
    }
  end

  private

  def sync_product_activity
    product.update_activity_status!
  end

  def resolve_size_and_color
    if size_name.present? && size_code.present?
      self.product_size =
        ProductSize.find_or_create_by!(
          code: size_code.strip.upcase
        ) do |ps|
          ps.name = size_name.strip.titleize
        end
    end

    if color_name.present?
      self.product_color =
        ProductColor.find_or_create_by!(
          name: color_name.strip.titleize
        ) do |pc|
          pc.hex_code = color_hex.presence
        end
    end
  end
end
