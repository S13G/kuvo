# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :product_categories
  has_many :categories, through: :product_categories

  has_many :product_variants
  has_many :product_sizes, through: :product_variants
  has_many :product_colors, through: :product_variants

  has_many :product_reviews
  has_many :product_images

  has_many :product_favorites, dependent: :destroy
  has_many :favorited_by_users, through: :product_favorites, source: :user

  before_create :set_created_by

  def self.ransackable_attributes(auth_object = nil)
    %w[created_by created_at description id is_active name price_cents updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[
      favorited_by_users
      product_categories
      categories
      product_colors
      product_favorites
      product_images
      product_reviews
      product_sizes
      product_variants
    ]
  end

  def average_rating
    product_reviews.average(:rating)&.round(1) || 0
  end

  def total_stock
    product_variants.sum(:stock)
  end

  def main_image
    product_images.main.first
  end

  def favorited_count
    product_favorites.count
  end

  def discounted_price_cents
    discount = Discount.active.first
    if discount.nil?
      return price_cents
    end

    price_cents - (price_cents * discount.percentage_off / 100)
  end

  def formatted_price
    Money.new(price_cents, CurrencySetting.currency).format
  end

  def formatted_discounted_price
    Money.new(discounted_price_cents, CurrencySetting.currency).format
  end

  private

  def set_created_by
    self.created_by = current_admin_user
  end
end
